import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import 'driver_profile_provider.dart';

/// 配達員の現在地を管理するProvider
///
/// デモ位置設定、GPS取得、DB保存位置の読み込みを統合管理
class DriverLocationNotifier extends StateNotifier<LatLng?> {
  final Ref ref;

  DriverLocationNotifier(this.ref) : super(null) {
    _initialize();
  }

  /// 初期化（DB → GPS の順で位置取得）
  Future<void> _initialize() async {
    // まずDBから読み込む（即座に利用可能）
    await _loadFromDatabase();

    // 次にGPSで更新（より正確）
    await updateFromGPS();
  }

  /// データベースから配達員の保存位置を読み込み
  Future<void> _loadFromDatabase() async {
    try {
      final profileAsync = ref.read(driverProfileProvider);
      profileAsync.whenData((profile) {
        if (profile.currentLatitude != null && profile.currentLongitude != null) {
          state = LatLng(profile.currentLatitude!, profile.currentLongitude!);
          print('[DriverLocation] Loaded from DB: ${state?.latitude}, ${state?.longitude}');
        }
      });
    } catch (e) {
      print('[DriverLocation] Error loading from DB: $e');
    }
  }

  /// GPSから現在地を取得して更新
  Future<void> updateFromGPS() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        state = LatLng(position.latitude, position.longitude);
        print('[DriverLocation] GPS updated: ${state?.latitude}, ${state?.longitude}');
      }
    } catch (e) {
      print('[DriverLocation] Error getting GPS: $e');
    }
  }

  /// デモ位置を設定（東京駅）
  void setDemoLocation() {
    state = LatLng(35.6812, 139.7671); // 東京駅
    print('[DriverLocation] Demo location set: Tokyo Station');
  }

  /// デモ位置をクリア（GPS位置に戻す）
  Future<void> clearDemoLocation() async {
    await updateFromGPS();
  }

  /// 手動で位置を設定
  void setLocation(double latitude, double longitude) {
    state = LatLng(latitude, longitude);
    print('[DriverLocation] Manual location set: $latitude, $longitude');
  }

  /// 現在地が東京周辺（デモ位置）かチェック
  bool get isDemoLocation {
    if (state == null) return false;
    // 東京駅から1km以内ならデモ位置とみなす
    final tokyoStation = LatLng(35.6812, 139.7671);
    final distance = const Distance().as(
      LengthUnit.Meter,
      state!,
      tokyoStation,
    );
    return distance < 1000; // 1km以内
  }

  /// 現在地が設定されているか
  bool get hasLocation => state != null;
}

/// 配達員の現在地Provider
final driverCurrentLocationProvider =
    StateNotifierProvider<DriverLocationNotifier, LatLng?>((ref) {
  return DriverLocationNotifier(ref);
});
