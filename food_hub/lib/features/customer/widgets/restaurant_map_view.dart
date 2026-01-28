import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/restaurant_model.dart';
import 'restaurant_mini_card.dart';

/// レストラン一覧（マップビュー）
class RestaurantMapView extends StatefulWidget {
  final List<RestaurantModel> restaurants;
  final List<Map<String, dynamic>> restaurantsWithDistance;
  final LatLng? currentLocation;
  final Function(RestaurantModel) onRestaurantTap;

  const RestaurantMapView({
    super.key,
    required this.restaurants,
    required this.restaurantsWithDistance,
    this.currentLocation,
    required this.onRestaurantTap,
  });

  @override
  State<RestaurantMapView> createState() => _RestaurantMapViewState();
}

class _RestaurantMapViewState extends State<RestaurantMapView> {
  late final MapController _mapController;
  RestaurantModel? _selectedRestaurant;

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
    // 地図の初期中心位置（現在地 or 東京駅）
    final center = widget.currentLocation ?? LatLng(35.6812, 139.7671);

    // 位置情報を持つレストランのみ
    final restaurantsWithLocation = widget.restaurants
        .where((r) => r.latitude != 0.0 && r.longitude != 0.0)
        .toList();

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
            onTap: (_, __) => setState(() => _selectedRestaurant = null), // 選択解除
          ),
          children: [
            // OpenStreetMap タイルレイヤー
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.foodhub.app',
              maxZoom: 19,
            ),

            // 現在地マーカー
            if (widget.currentLocation != null)
              MarkerLayer(
                markers: [_buildCurrentLocationMarker()],
              ),

            // レストランマーカー
            MarkerLayer(
              markers: restaurantsWithLocation.map(_buildRestaurantMarker).toList(),
            ),
          ],
        ),

        // レストラン数バッジ（右上）
        if (restaurantsWithLocation.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: _buildCountBadge(restaurantsWithLocation.length),
          ),

        // 現在地ボタン（右下）
        if (widget.currentLocation != null)
          Positioned(
            bottom: _selectedRestaurant != null ? 140 : 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                _mapController.move(
                  widget.currentLocation!,
                  _mapController.camera.zoom,
                );
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

        // 選択中のレストランカード（下部）
        if (_selectedRestaurant != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RestaurantMiniCard(
              restaurant: _selectedRestaurant!,
              distance: _getDistanceForRestaurant(_selectedRestaurant!),
              onTap: () => widget.onRestaurantTap(_selectedRestaurant!),
            ),
          ),

        // レストランが0件の場合
        if (restaurantsWithLocation.isEmpty)
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
                    'この条件のレストランは\n地図に表示できません',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '他の条件をお試しください',
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

  /// 現在地マーカー
  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: widget.currentLocation!,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 16,
          ),
        ),
      ),
    );
  }

  /// レストランマーカー
  Marker _buildRestaurantMarker(RestaurantModel restaurant) {
    final isSelected = _selectedRestaurant?.id == restaurant.id;

    return Marker(
      point: LatLng(restaurant.latitude, restaurant.longitude),
      width: isSelected ? 70 : 60,
      height: isSelected ? 70 : 60,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRestaurant = restaurant);
          // 選択マーカーを中心に移動
          _mapController.move(
            LatLng(restaurant.latitude, restaurant.longitude),
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
              color: isSelected ? Colors.black : Colors.grey[700],
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
                  restaurant.deliveryFee == 0
                      ? '無料'
                      : '¥${restaurant.deliveryFee.toInt()}',
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

  /// レストラン数バッジ
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
          const Icon(Icons.restaurant, color: Colors.black, size: 16),
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

  /// 距離取得（restaurantsWithDistanceから）
  double? _getDistanceForRestaurant(RestaurantModel restaurant) {
    try {
      final item = widget.restaurantsWithDistance.firstWhere(
        (item) => (item['restaurant'] as RestaurantModel).id == restaurant.id,
      );
      return item['distance'] as double?;
    } catch (e) {
      return null;
    }
  }
}
