import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../shared/constants/app_constants.dart';

/// Socket.IOサービス - リアルタイム配達員位置更新
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _driverLocationController = StreamController<DriverLocationUpdate>.broadcast();

  /// 配達員位置更新ストリーム
  Stream<DriverLocationUpdate> get driverLocationStream => _driverLocationController.stream;

  /// Socket.IO接続状態
  bool get isConnected => _socket?.connected ?? false;

  /// 接続
  void connect() {
    if (_socket?.connected == true) {
      print('[SocketService] Already connected');
      return;
    }

    print('[SocketService] Connecting to ${AppConstants.socketUrl}');

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // WebSocketのみ使用
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    // 接続成功
    _socket!.on('connect', (_) {
      print('[SocketService] ✅ Connected to server');
    });

    // 切断
    _socket!.on('disconnect', (_) {
      print('[SocketService] ❌ Disconnected from server');
    });

    // 接続エラー
    _socket!.on('connect_error', (error) {
      print('[SocketService] ❌ Connection error: $error');
    });

    // 配達員位置更新イベント
    _socket!.on('driver:location-changed', (data) {
      try {
        print('[SocketService] 📍 Driver location update received: $data');
        final update = DriverLocationUpdate.fromJson(data);
        _driverLocationController.add(update);
      } catch (e) {
        print('[SocketService] Error parsing driver location: $e');
      }
    });
  }

  /// 切断
  void disconnect() {
    print('[SocketService] Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// リソース解放
  void dispose() {
    disconnect();
    _driverLocationController.close();
  }
}

/// 配達員位置更新データ
class DriverLocationUpdate {
  final int driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  DriverLocationUpdate({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory DriverLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DriverLocationUpdate(
      driverId: json['driverId'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
