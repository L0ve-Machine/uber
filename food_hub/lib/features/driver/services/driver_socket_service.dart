import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../shared/constants/app_constants.dart';
import 'location_service.dart';

/// 配達員用Socket.IOサービス - リアルタイム位置情報送信
class DriverSocketService {
  final int driverId;
  final String authToken;

  IO.Socket? _socket;
  Timer? _locationTimer;
  bool _isConnected = false;
  bool _isLocationUpdating = false;

  DriverSocketService({
    required this.driverId,
    required this.authToken,
  });

  /// Socket.IO接続状態
  bool get isConnected => _isConnected;

  /// 位置更新中か
  bool get isLocationUpdating => _isLocationUpdating;

  /// Socket.IOサーバーに接続
  void connect() {
    if (_socket?.connected == true) {
      print('[DriverSocket] Already connected');
      return;
    }

    print('[DriverSocket] Connecting to ${AppConstants.socketUrl}');

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $authToken'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    // 接続成功
    _socket!.on('connect', (_) {
      print('[DriverSocket] ✅ Connected to server');
      _isConnected = true;
      _registerDriver();
    });

    // 配達員登録成功
    _socket!.on('driver:registered', (data) {
      print('[DriverSocket] ✅ Driver registered successfully');
      startLocationUpdates();
    });

    // 切断
    _socket!.on('disconnect', (_) {
      print('[DriverSocket] ❌ Disconnected from server');
      _isConnected = false;
      stopLocationUpdates();
    });

    // 接続エラー
    _socket!.on('connect_error', (error) {
      print('[DriverSocket] ⚠️ Connection error: $error');
      _isConnected = false;
    });

    // タイムアウト
    _socket!.on('connect_timeout', (_) {
      print('[DriverSocket] ⚠️ Connection timeout');
    });

    // エラー
    _socket!.on('error', (error) {
      print('[DriverSocket] ⚠️ Socket error: $error');
    });
  }

  /// 配達員をサーバーに登録
  void _registerDriver() {
    if (_socket?.connected != true) {
      print('[DriverSocket] Cannot register - not connected');
      return;
    }

    print('[DriverSocket] Registering driver $driverId');
    _socket!.emit('driver:register', {
      'driverId': driverId,
      'token': authToken,
    });
  }

  /// 位置情報の定期送信を開始
  Future<void> startLocationUpdates() async {
    if (_isLocationUpdating) {
      print('[DriverSocket] Location updates already running');
      return;
    }

    // 権限チェック
    final hasPermission = await LocationService.checkAndRequestPermission();
    if (!hasPermission) {
      print('[DriverSocket] ❌ Location permission not granted');
      return;
    }

    print('[DriverSocket] 📍 Starting location updates (every 10 seconds)');
    _isLocationUpdating = true;

    // 最初の位置情報を即座に送信
    await _sendLocationUpdate();

    // 10秒ごとに位置情報を送信
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _sendLocationUpdate();
    });
  }

  /// 位置情報を取得してサーバーに送信
  Future<void> _sendLocationUpdate() async {
    if (_socket?.connected != true) {
      print('[DriverSocket] Cannot send location - not connected');
      return;
    }

    try {
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        print('[DriverSocket] ⚠️ Could not get current position');
        return;
      }

      // Socket.IOで送信
      _socket!.emit('driver:location-update', {
        'driverId': driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      print('[DriverSocket] 📍 Location sent: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}');
    } catch (e) {
      print('[DriverSocket] ⚠️ Error sending location: $e');
    }
  }

  /// 位置情報の定期送信を停止
  void stopLocationUpdates() {
    if (!_isLocationUpdating) {
      return;
    }

    print('[DriverSocket] 🛑 Stopping location updates');
    _locationTimer?.cancel();
    _locationTimer = null;
    _isLocationUpdating = false;
  }

  /// Socket.IO接続を切断
  void disconnect() {
    print('[DriverSocket] Disconnecting...');
    stopLocationUpdates();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// リソース解放
  void dispose() {
    disconnect();
  }
}
