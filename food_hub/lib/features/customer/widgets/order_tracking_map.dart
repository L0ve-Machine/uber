import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 注文追跡用の地図ウィジェット（OpenStreetMap使用）
class OrderTrackingMap extends StatefulWidget {
  final double? driverLatitude;
  final double? driverLongitude;
  final double restaurantLatitude;
  final double restaurantLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final bool showDriverLocation;
  final String orderStatus;
  final bool hasDriver;
  final String? restaurantName;

  const OrderTrackingMap({
    super.key,
    this.driverLatitude,
    this.driverLongitude,
    required this.restaurantLatitude,
    required this.restaurantLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.showDriverLocation = false,
    required this.orderStatus,
    required this.hasDriver,
    this.restaurantName,
  });

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 地図の中心を計算（配達先をデフォルト）
    final center = LatLng(widget.deliveryLatitude, widget.deliveryLongitude);

    // マーカーリスト
    final markers = <Marker>[
      // レストランマーカー
      Marker(
        point: LatLng(widget.restaurantLatitude, widget.restaurantLongitude),
        width: 40,
        height: 40,
        child: const Icon(
          Icons.restaurant,
          color: Colors.orange,
          size: 40,
        ),
      ),
      // 配達先マーカー
      Marker(
        point: LatLng(widget.deliveryLatitude, widget.deliveryLongitude),
        width: 40,
        height: 40,
        child: const Icon(
          Icons.home,
          color: Colors.blue,
          size: 40,
        ),
      ),
    ];

    // 配達員の位置が表示可能な場合のみ追加
    if (widget.showDriverLocation &&
        widget.driverLatitude != null &&
        widget.driverLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(widget.driverLatitude!, widget.driverLongitude!),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }

    return Container(
      height: 300,
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
                // OpenStreetMap タイルレイヤー
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.foodhub.app',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(),
                ),
                // マーカーレイヤー
                MarkerLayer(markers: markers),
                // ルート線（オプション）
                if (widget.showDriverLocation &&
                    widget.driverLatitude != null &&
                    widget.driverLongitude != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(widget.driverLatitude!, widget.driverLongitude!),
                          LatLng(widget.deliveryLatitude, widget.deliveryLongitude),
                        ],
                        color: Colors.blue,
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),
              ],
            ),
            // 凡例
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
                    if (widget.showDriverLocation &&
                        widget.driverLatitude != null &&
                        widget.driverLongitude != null) ...[
                      const SizedBox(height: 4),
                      _buildLegendItem(Icons.delivery_dining, Colors.green, '配達員'),
                    ],
                  ],
                ),
              ),
            ),
            // ステータスメッセージ
            if (_getStatusMessage() != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusMessageColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusMessageIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getStatusMessage()!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

  /// ステータスに応じたメッセージを取得
  String? _getStatusMessage() {
    switch (widget.orderStatus) {
      case 'pending':
        return '店舗の承認待ちです';
      case 'accepted':
        return '調理準備中';
      case 'preparing':
        return '調理中';
      case 'ready':
        if (!widget.hasDriver) {
          return '配達員を探しています';
        }
        return null; // 配達員割り当て済みなら非表示
      case 'picked_up':
        if (!widget.showDriverLocation) {
          return 'レストランから配達先に向かっています';
        }
        return _isDriverNearDelivery() ? 'もうすぐ到着します' : '配達中です';
      case 'delivering':
        return _isDriverNearDelivery() ? 'もうすぐ到着します' : '配達中です';
      case 'delivered':
      case 'cancelled':
        return null; // 完了・キャンセル時は非表示
      default:
        return null;
    }
  }

  /// 配達員が配達先に近いか判定（100m以内）
  bool _isDriverNearDelivery() {
    if (widget.driverLatitude == null || widget.driverLongitude == null) {
      return false;
    }

    final distance = const Distance().as(
      LengthUnit.Meter,
      LatLng(widget.driverLatitude!, widget.driverLongitude!),
      LatLng(widget.deliveryLatitude, widget.deliveryLongitude),
    );

    return distance < 100; // 100m以内なら「もうすぐ到着」
  }

  /// ステータスメッセージの背景色
  Color _getStatusMessageColor() {
    switch (widget.orderStatus) {
      case 'pending':
      case 'accepted':
        return Colors.orange.withOpacity(0.9);
      case 'preparing':
        return Colors.purple.withOpacity(0.9);
      case 'ready':
        return Colors.blue.withOpacity(0.9);
      case 'picked_up':
      case 'delivering':
        return _isDriverNearDelivery()
            ? Colors.green.withOpacity(0.9)
            : Colors.black.withOpacity(0.9);
      default:
        return Colors.black87;
    }
  }

  /// ステータスメッセージのアイコン
  IconData _getStatusMessageIcon() {
    switch (widget.orderStatus) {
      case 'pending':
      case 'accepted':
        return Icons.schedule;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.search;
      case 'picked_up':
      case 'delivering':
        return _isDriverNearDelivery()
            ? Icons.near_me
            : Icons.delivery_dining;
      default:
        return Icons.info_outline;
    }
  }
}
