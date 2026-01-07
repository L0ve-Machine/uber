import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 地図上で位置を選択できるウィジェット
class LocationPickerMap extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double lat, double lon) onLocationSelected;
  final double height;

  const LocationPickerMap({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.height = 350,
  }) : super(key: key);

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // 初期位置を設定（デフォルトは東京駅）
    _selectedLocation = LatLng(
      widget.initialLatitude ?? 35.6812,
      widget.initialLongitude ?? 139.7671,
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    print('[LocationPickerMap] Map tapped: lat=${latLng.latitude}, lon=${latLng.longitude}');
    setState(() {
      _selectedLocation = latLng;
    });
    widget.onLocationSelected(latLng.latitude, latLng.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
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
                initialCenter: _selectedLocation,
                initialZoom: 15.0,
                minZoom: 10.0,
                maxZoom: 18.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.foodhub.app',
                  maxZoom: 19,
                  tileProvider: NetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // 操作説明
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.black, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '地図をタップして配達先の位置を選択',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
}
