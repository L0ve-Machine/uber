import 'package:geolocator/geolocator.dart';

/// 位置情報サービス - 権限管理と位置取得
class LocationService {
  /// 位置情報の権限をチェックしてリクエスト
  static Future<bool> checkAndRequestPermission() async {
    // 位置情報サービスが有効か確認
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[LocationService] Location services are disabled.');
      return false;
    }

    // 権限をチェック
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[LocationService] Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[LocationService] Location permissions are permanently denied');
      return false;
    }

    print('[LocationService] Location permission granted');
    return true;
  }

  /// 現在位置を取得
  static Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('[LocationService] Error getting position: $e');
      return null;
    }
  }

  /// 位置情報サービスが有効か確認
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// アプリの位置情報設定画面を開く
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// アプリ設定画面を開く（権限が永久拒否された場合）
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
