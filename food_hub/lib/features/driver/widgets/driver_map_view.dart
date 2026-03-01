import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/order_model.dart';

/// 配達リクエスト地図ビュー（ヒートマップ + クラスタリング）
class DriverMapView extends StatefulWidget {
  final List<OrderModel> availableOrders;
  final LatLng? driverLocation;
  final Function(OrderModel) onOrderTap;

  const DriverMapView({
    super.key,
    required this.availableOrders,
    this.driverLocation,
    required this.onOrderTap,
  });

  @override
  State<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  late final MapController _mapController;
  OrderModel? _selectedOrder;

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
    // 地図の初期中心位置（配達員の現在地 or 東京駅）
    final center = widget.driverLocation ?? LatLng(35.6812, 139.7671);

    // 位置情報を持つ配達リクエストのみフィルター
    final ordersWithLocation = widget.availableOrders
        .where((order) =>
            order.restaurant?.latitude != null &&
            order.restaurant?.longitude != null)
        .toList();

    // クラスタリング判定（50件以上でクラスタリング有効）
    final shouldCluster = ordersWithLocation.length >= 50;

    return Stack(
      children: [
        // 地図本体
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
            minZoom: 10.0,
            maxZoom: 18.0,
            onTap: (_, __) => setState(() => _selectedOrder = null), // 選択解除
          ),
          children: [
            // 1. OpenStreetMap タイルレイヤー
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.foodhub.app',
              maxZoom: 19,
            ),

            // 2. ヒートマップレイヤー（常時表示）
            if (ordersWithLocation.isNotEmpty)
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(
                  data: _generateHeatmapData(),
                ),
                heatMapOptions: HeatMapOptions(
                  gradient: {
                    0.0: Colors.blue,
                    0.4: Colors.green,
                    0.6: Colors.yellow,
                    0.8: Colors.orange,
                    1.0: Colors.red,
                  },
                  minOpacity: 0.2,
                  radius: 50,
                ),
              ),

            // 3. クラスタリングレイヤー or 個別マーカー
            if (shouldCluster)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  markers: _buildOrderMarkers(),
                  builder: (context, markers) => _buildClusterMarker(markers),
                ),
              )
            else
              MarkerLayer(
                markers: _buildOrderMarkers(),
              ),

            // 4. 配達員の現在地マーカー
            if (widget.driverLocation != null)
              MarkerLayer(
                markers: [_buildDriverMarker()],
              ),
          ],
        ),

        // 配達リクエスト数バッジ（右上）
        if (ordersWithLocation.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: _buildCountBadge(ordersWithLocation.length),
          ),

        // 現在地ボタン（右下）
        if (widget.driverLocation != null)
          Positioned(
            bottom: _selectedOrder != null ? 140 : 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(
                  widget.driverLocation!,
                  _mapController.camera.zoom,
                );
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

        // 選択中の配達カード（下部）
        if (_selectedOrder != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSelectedOrderCard(_selectedOrder!),
          ),

        // 配達リクエストが0件の場合
        if (ordersWithLocation.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '現在利用可能な配達リクエストは\n地図に表示できません',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'オンライン状態を確認してください',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// ヒートマップデータを生成
  List<WeightedLatLng> _generateHeatmapData() {
    return widget.availableOrders
        .where((order) =>
            order.restaurant?.latitude != null &&
            order.restaurant?.longitude != null)
        .map((order) => WeightedLatLng(
              LatLng(
                order.restaurant!.latitude!,
                order.restaurant!.longitude!,
              ),
              1.0, // 全て同じ重み（将来的に配送料で重み付け可能）
            ))
        .toList();
  }

  /// 配達リクエストマーカーリストを生成
  List<Marker> _buildOrderMarkers() {
    return widget.availableOrders
        .where((order) =>
            order.restaurant?.latitude != null &&
            order.restaurant?.longitude != null)
        .map((order) => _buildOrderMarker(order))
        .toList();
  }

  /// 個別の配達リクエストマーカー
  Marker _buildOrderMarker(OrderModel order) {
    final isSelected = _selectedOrder?.id == order.id;

    return Marker(
      point: LatLng(
        order.restaurant!.latitude!,
        order.restaurant!.longitude!,
      ),
      width: isSelected ? 70 : 60,
      height: isSelected ? 70 : 60,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedOrder = order);
          // 選択マーカーを中心に移動
          _mapController.move(
            LatLng(
              order.restaurant!.latitude!,
              order.restaurant!.longitude!,
            ),
            _mapController.camera.zoom >= 14 ? _mapController.camera.zoom : 14,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ピンアイコン
            Icon(
              Icons.location_on,
              color: isSelected ? Colors.orange : Colors.orange[300],
              size: isSelected ? 70 : 60,
            ),
            // 配送料表示
            Positioned(
              top: isSelected ? 10 : 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '¥${order.deliveryFee.toInt()}',
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// クラスタマーカー（密集度に応じた色分け）
  Widget _buildClusterMarker(List<Marker> markers) {
    final count = markers.length;

    // 4段階の色分け（確定仕様）
    Color clusterColor;
    if (count <= 5) {
      clusterColor = Colors.green[600]!; // 🟢 1-5件: 余裕あり
    } else if (count <= 15) {
      clusterColor = Colors.yellow[700]!; // 🟡 6-15件: やや混雑
    } else if (count <= 39) {
      clusterColor = Colors.orange[700]!; // 🟠 16-39件: 混雑
    } else {
      clusterColor = Colors.red[700]!; // 🔴 40件以上: 非常に混雑
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: clusterColor,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// 配達員の現在地マーカー
  Marker _buildDriverMarker() {
    return Marker(
      point: widget.driverLocation!,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.delivery_dining,
            color: Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// 配達リクエスト数バッジ
  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping, color: Colors.black, size: 16),
          const SizedBox(width: 6),
          Text(
            '$count件',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 選択中の配達カード
  Widget _buildSelectedOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () => widget.onOrderTap(order),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.restaurant?.name ?? 'レストラン',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '¥${order.deliveryFee.toInt()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (order.restaurant?.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.restaurant!.address!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
