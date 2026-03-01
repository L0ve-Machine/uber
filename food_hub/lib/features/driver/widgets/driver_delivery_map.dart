import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/routing_service.dart';

/// 配達員用の配達ルート地図ウィジェット
class DriverDeliveryMap extends StatefulWidget {
  final double driverLatitude;
  final double driverLongitude;
  final double restaurantLatitude;
  final double restaurantLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final String orderStatus;
  final String? restaurantName;

  const DriverDeliveryMap({
    super.key,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.orderStatus,
    this.restaurantName,
  });

  @override
  State<DriverDeliveryMap> createState() => _DriverDeliveryMapState();
}

class _DriverDeliveryMapState extends State<DriverDeliveryMap> {
  late final MapController _mapController;
  List<LatLng>? _routeToRestaurant; // レストランへのルート
  List<LatLng>? _routeToDelivery; // 配達先へのルート
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchRoutes();
  }

  /// ルートを取得
  Future<void> _fetchRoutes() async {
    final restaurantPoint = LatLng(widget.restaurantLatitude, widget.restaurantLongitude);
    final driverPoint = LatLng(widget.driverLatitude, widget.driverLongitude);
    final deliveryPoint = LatLng(widget.deliveryLatitude, widget.deliveryLongitude);

    // 並行してルートを取得
    final results = await Future.wait([
      RoutingService.getRoute(restaurantPoint, driverPoint),
      RoutingService.getRoute(driverPoint, deliveryPoint),
    ]);

    if (mounted) {
      setState(() {
        _routeToRestaurant = results[0];
        _routeToDelivery = results[1];
        _isLoadingRoute = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 地図の中心を配達員の現在地に設定
    final center = LatLng(widget.driverLatitude, widget.driverLongitude);

    return Column(
      children: [
        // 地図本体
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // 1. OpenStreetMap タイルレイヤー
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.foodhub.app',
                      maxZoom: 19,
                    ),

                    // 2. ルート線レイヤー
                    PolylineLayer(
                      polylines: _buildRoutePolylines(),
                    ),

                    // 3. マーカーレイヤー
                    MarkerLayer(
                      markers: [
                        _buildRestaurantMarker(),
                        _buildDeliveryMarker(),
                        _buildDriverMarker(),
                      ],
                    ),
                  ],
                ),

                // 凡例（右上）
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(Icons.restaurant, Colors.orange, 'レストラン'),
                        const SizedBox(height: 4),
                        _buildLegendItem(Icons.home, Colors.blue, 'お届け先'),
                        const SizedBox(height: 4),
                        _buildLegendItem(Icons.navigation, Colors.green, 'あなた'),
                      ],
                    ),
                  ),
                ),

                // 現在地ボタン（右下）
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(
                        LatLng(widget.driverLatitude, widget.driverLongitude),
                        14.0,
                      );
                    },
                    child: const Icon(Icons.my_location, color: Colors.black, size: 20),
                  ),
                ),

                // ルート読み込み中インジケーター
                if (_isLoadingRoute)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ルート取得中...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 距離・時間情報バー
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.straighten,
                label: '残り距離',
                value: '${_calculateRemainingDistance().toStringAsFixed(1)}km',
                color: Colors.blue,
              ),
              Container(width: 1, height: 30, color: Colors.grey[300]),
              _buildInfoItem(
                icon: Icons.access_time,
                label: '到着予定',
                value: _estimateArrivalTime(),
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ルート線を構築（ステータス別、実際の道路に沿う）
  List<Polyline> _buildRoutePolylines() {
    final polylines = <Polyline>[];

    // ルート取得中はローディング表示のため空を返す
    if (_isLoadingRoute || _routeToRestaurant == null || _routeToDelivery == null) {
      return polylines;
    }

    if (widget.orderStatus == 'ready') {
      // ピックアップ前: レストラン → 配達員（緑の線）
      polylines.add(
        Polyline(
          points: _routeToRestaurant!,
          color: Colors.green,
          strokeWidth: 3.0,
        ),
      );
      // 配達員 → 配達先（薄い青）
      polylines.add(
        Polyline(
          points: _routeToDelivery!,
          color: Colors.blue.withOpacity(0.4),
          strokeWidth: 2.0,
        ),
      );
    } else if (widget.orderStatus == 'picked_up') {
      // ピックアップ済み: 配達員 → 配達先（青の太線）
      polylines.add(
        Polyline(
          points: _routeToDelivery!,
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
      // レストラン → 配達員（完了済み、薄いグレー）
      polylines.add(
        Polyline(
          points: _routeToRestaurant!,
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 2.0,
        ),
      );
    } else if (widget.orderStatus == 'delivering') {
      // 配達中: 配達員 → 配達先（青の極太線）
      polylines.add(
        Polyline(
          points: _routeToDelivery!,
          color: Colors.blue,
          strokeWidth: 5.0,
        ),
      );
    }

    return polylines;
  }

  /// レストランマーカー
  Marker _buildRestaurantMarker() {
    final isPickupPending = widget.orderStatus == 'ready';

    return Marker(
      point: LatLng(widget.restaurantLatitude, widget.restaurantLongitude),
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.restaurant,
            color: isPickupPending ? Colors.orange : Colors.grey,
            size: 50,
          ),
          // ピックアップ待ちなら赤いバッジ
          if (isPickupPending)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 配達先マーカー
  Marker _buildDeliveryMarker() {
    final isDelivering = widget.orderStatus == 'delivering' || widget.orderStatus == 'picked_up';

    return Marker(
      point: LatLng(widget.deliveryLatitude, widget.deliveryLongitude),
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isDelivering
              ? Border.all(color: Colors.red, width: 3)
              : null,
        ),
        child: Icon(
          Icons.home,
          color: Colors.blue,
          size: 50,
        ),
      ),
    );
  }

  /// 配達員マーカー（自分）
  Marker _buildDriverMarker() {
    return Marker(
      point: LatLng(widget.driverLatitude, widget.driverLongitude),
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.navigation,
            color: Colors.green,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// 凡例アイテム
  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  /// 情報アイテム（距離・時間）
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 残り距離を計算（配達員 → 配達先、ルートベース）
  double _calculateRemainingDistance() {
    if (_routeToDelivery != null && _routeToDelivery!.length >= 2) {
      // ルートに沿った距離を計算
      return RoutingService.calculateRouteDistance(_routeToDelivery!) / 1000; // kmに変換
    }

    // フォールバック: 直線距離
    return const Distance().as(
      LengthUnit.Meter,
      LatLng(widget.driverLatitude, widget.driverLongitude),
      LatLng(widget.deliveryLatitude, widget.deliveryLongitude),
    ) / 1000; // kmに変換
  }

  /// 到着予定時刻を推定（平均速度20km/hと仮定）
  String _estimateArrivalTime() {
    final distanceKm = _calculateRemainingDistance();
    return RoutingService.estimateArrivalTimeString(distanceKm);
  }
}
