import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// バックグラウンド位置情報追跡サービス
@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String _notificationChannelId = 'driver_location_tracking';
  static const String _notificationChannelName = '配達追跡';
  static const int _notificationId = 888;

  /// サービスの初期化
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // 通知チャンネルの作成（Android）
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: '配達中の位置情報を送信しています',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // サービスの設定
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: '配達中',
        initialNotificationContent: '位置情報を送信中...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// サービス開始
  @pragma('vm:entry-point')
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
    print('[BackgroundLocation] Service started');
  }

  /// サービス停止
  @pragma('vm:entry-point')
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
    print('[BackgroundLocation] Service stop requested');
  }

  /// バックグラウンドで実行されるメインエントリーポイント
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('[BackgroundLocation] onStart called');

    // SharedPreferencesから配達員情報を取得
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getInt('driver_id');
    final authToken = prefs.getString('auth_token');
    final socketUrl = prefs.getString('socket_url') ?? 'https://133-117-77-23.nip.io';

    if (driverId == null || authToken == null) {
      print('[BackgroundLocation] ❌ Missing driver credentials');
      service.stopSelf();
      return;
    }

    print('[BackgroundLocation] Driver ID: $driverId');

    // Socket.IO接続
    final socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .build(),
    );

    socket.connect();

    // 接続成功
    socket.on('connect', (_) {
      print('[BackgroundLocation] ✅ Socket connected');

      // 配達員登録
      socket.emit('driver:register', {
        'driverId': driverId,
        'token': authToken,
      });
    });

    socket.on('driver:registered', (_) {
      print('[BackgroundLocation] ✅ Driver registered');
    });

    socket.on('connect_error', (error) {
      print('[BackgroundLocation] ⚠️ Connection error: $error');
    });

    socket.on('disconnect', (_) {
      print('[BackgroundLocation] ❌ Socket disconnected');
    });

    // 位置情報の定期送信（10秒ごと）
    Timer? locationTimer;
    int updateCount = 0;

    // 最初の位置情報を即座に送信
    _sendLocation(socket, driverId, service);

    locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      updateCount++;
      await _sendLocation(socket, driverId, service, count: updateCount);
    });

    // 停止シグナルを監視
    service.on('stop').listen((event) {
      print('[BackgroundLocation] Stop signal received');
      locationTimer?.cancel();
      socket.disconnect();
      service.stopSelf();
    });

    // 定期的に生存確認（30秒ごと）
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (service is! AndroidServiceInstance) return;

      service.setForegroundNotificationInfo(
        title: '配達中',
        content: '位置情報を送信中... (更新回数: $updateCount)',
      );
    });
  }

  /// 位置情報を取得して送信
  @pragma('vm:entry-point')
  static Future<void> _sendLocation(
    IO.Socket socket,
    int driverId,
    ServiceInstance service, {
    int count = 0,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      socket.emit('driver:location-update', {
        'driverId': driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      print('[BackgroundLocation] 📍 Location sent #$count: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');

      // 通知を更新（Android）
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: '配達中',
          content: '位置情報を送信中... (最終更新: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})',
        );
      }
    } catch (e) {
      print('[BackgroundLocation] ⚠️ Error getting/sending location: $e');
    }
  }

  /// iOS用バックグラウンド処理
  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    print('[BackgroundLocation] iOS background execution');
    return true;
  }
}
