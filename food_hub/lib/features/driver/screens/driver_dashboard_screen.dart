import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../widgets/driver_order_card.dart';
import '../widgets/pickup_pin_dialog.dart';
import '../services/background_location_service.dart';
import '../services/location_service.dart';
import 'driver_active_delivery_screen.dart';
import 'driver_stripe_setup_screen.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  int _currentIndex = 0;
  bool _locationPermissionGranted = false;
  bool _backgroundServiceInitialized = false;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _maxDistancePreference; // 距離上限設定

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
    _loadDriverLocation(); // 先にDBから位置を読み込む
    _loadMaxDistancePreference();
  }

  /// 配達員の位置を読み込み（DB → GPS）
  Future<void> _loadDriverLocation() async {
    try {
      // まずDBから読み込む（即座に利用可能）
      final repository = ref.read(driverRepositoryProvider);
      final result = await repository.getProfile();

      result.when(
        success: (profile) {
          if (profile.currentLatitude != null && profile.currentLongitude != null) {
            if (mounted) {
              setState(() {
                _currentLatitude = profile.currentLatitude;
                _currentLongitude = profile.currentLongitude;
              });
              print('[DriverDashboard] Loaded saved location: $_currentLatitude, $_currentLongitude');
            }
          } else {
            print('[DriverDashboard] No saved location in profile');
          }
        },
        failure: (error) {
          print('[DriverDashboard] Error loading profile: $error');
        },
      );
    } catch (e) {
      print('[DriverDashboard] Error loading saved location: $e');
    }

    // 次にGPSで更新（より正確な位置）
    _getCurrentLocation();
  }

  /// 距離上限設定を読み込み
  Future<void> _loadMaxDistancePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final maxDistance = prefs.getDouble('driver_max_distance');
    if (mounted) {
      setState(() {
        _maxDistancePreference = maxDistance;
      });
    }
  }

  /// 配達員の現在地を取得（GPS）
  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
        });
        print('[DriverDashboard] GPS location updated: $_currentLatitude, $_currentLongitude');
      } else {
        print('[DriverDashboard] GPS location unavailable');
      }
    } catch (e) {
      print('[DriverDashboard] Error getting GPS location: $e');
    }
  }

  /// バックグラウンドサービスを初期化
  Future<void> _initializeBackgroundService() async {
    // 権限チェック
    final hasPermission = await LocationService.checkAndRequestPermission();
    setState(() {
      _locationPermissionGranted = hasPermission;
    });

    if (!hasPermission) {
      print('[DriverDashboard] Location permission not granted');
      return;
    }

    // SharedPreferencesに認証情報を保存（既存セッション対応）
    final user = ref.read(authProvider).value;
    if (user != null && user.userType == 'driver') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = await SecureStorage.getToken();

        await prefs.setInt('driver_id', user.id);
        if (token != null) {
          await prefs.setString('auth_token', token);
        }
        await prefs.setString('socket_url', 'https://133-117-77-23.nip.io');
        print('[DriverDashboard] Saved credentials to SharedPreferences');
      } catch (e) {
        print('[DriverDashboard] Error saving credentials: $e');
      }
    }

    // バックグラウンドサービスを初期化
    try {
      await BackgroundLocationService.initialize();
      setState(() {
        _backgroundServiceInitialized = true;
      });
      print('[DriverDashboard] Background service initialized');

      // オンライン状態ならサービスを開始
      final isOnline = ref.read(driverOnlineStatusProvider);
      if (isOnline) {
        await BackgroundLocationService.start();
      }
    } catch (e) {
      print('[DriverDashboard] Error initializing background service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final isOnline = ref.watch(driverOnlineStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Driver info and online toggle
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user != null) ...[
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phone,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Online/Offline toggle
                Column(
                  children: [
                    Switch(
                      value: isOnline,
                      onChanged: (value) => _handleToggleOnline(value),
                      activeColor: AppColors.success,
                    ),
                    Text(
                      isOnline ? 'オンライン' : 'オフライン',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOnline ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats summary
          _buildStatsSection(),

          // Content based on tab
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: '配達',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return '配達ダッシュボード';
      case 1:
        return '配達履歴';
      case 2:
        return '設定';
      default:
        return '配達ダッシュボード';
    }
  }

  void _handleRefresh() {
    if (_currentIndex == 0) {
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(activeDeliveriesProvider);
      ref.invalidate(driverStatsProvider());
    } else {
      ref.invalidate(driverOrderHistoryProvider);
    }
  }

  Widget _buildStatsSection() {
    final statsAsync = ref.watch(driverStatsProvider());

    return statsAsync.when(
      data: (stats) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.delivery_dining,
                label: '本日の配達',
                value: '${stats.totalDeliveries}件',
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                label: '本日の収入',
                value: '¥${stats.totalEarnings.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isOnline = ref.watch(driverOnlineStatusProvider);

    if (_currentIndex == 0) {
      if (!isOnline) {
        return const EmptyState(
          icon: Icons.offline_bolt_outlined,
          title: 'オフライン中',
          message: 'オンラインに切り替えると配達リクエストを受け取れます',
        );
      }
      return _buildDeliveryTab();
    } else if (_currentIndex == 1) {
      return _buildHistoryTab();
    } else {
      return _buildSettingsTab();
    }
  }

  Widget _buildDeliveryTab() {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);
    final availableOrdersAsync = ref.watch(availableOrdersProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active deliveries section
          activeDeliveriesAsync.when(
            data: (activeOrders) {
              if (activeOrders.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '現在の配達',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...activeOrders.map((order) {
                      // 距離計算
                      double? distanceToRestaurant;
                      double? distanceToCustomer;

                      if (_currentLatitude != null && _currentLongitude != null) {
                        // 現在地 → レストラン
                        if (order.restaurant?.latitude != null && order.restaurant?.longitude != null) {
                          distanceToRestaurant = Geolocator.distanceBetween(
                            _currentLatitude!,
                            _currentLongitude!,
                            order.restaurant!.latitude!,
                            order.restaurant!.longitude!,
                          ) / 1000; // km変換
                        }

                        // レストラン → 配達先
                        if (order.restaurant?.latitude != null &&
                            order.restaurant?.longitude != null &&
                            order.deliveryAddress?.latitude != null &&
                            order.deliveryAddress?.longitude != null) {
                          distanceToCustomer = Geolocator.distanceBetween(
                            order.restaurant!.latitude!,
                            order.restaurant!.longitude!,
                            order.deliveryAddress!.latitude!,
                            order.deliveryAddress!.longitude!,
                          ) / 1000; // km変換
                        }
                      }

                      return DriverOrderCard(
                        order: order,
                        distanceToRestaurant: distanceToRestaurant,
                        distanceToCustomer: distanceToCustomer,
                        onTap: () => _navigateToActiveDelivery(order.id),
                        onStartDelivering: order.status == 'picked_up'
                            ? () => _handleStartDeliveringWithoutPin(order.id)
                            : () => _handleStartDelivering(order.id),
                        onCompleteDelivery: () => _handleCompleteDelivery(order.id),
                      );
                    }),
                    const Divider(height: 32),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Available orders section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '利用可能な配達',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          availableOrdersAsync.when(
            data: (orders) {
              print('[DriverDashboard] Total available orders: ${orders.length}');
              print('[DriverDashboard] Current location: $_currentLatitude, $_currentLongitude');
              print('[DriverDashboard] Max distance preference: $_maxDistancePreference');

              // 位置情報がない場合の警告
              if (_currentLatitude == null || _currentLongitude == null) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off, size: 48, color: Colors.orange[700]),
                        const SizedBox(height: 16),
                        const Text(
                          '位置情報を取得中...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '位置情報が取得できない場合、\n設定から位置情報の権限を確認してください',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadDriverLocation();
                            ref.invalidate(availableOrdersProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('再読み込み'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 距離でフィルタリング
              final filteredOrders = orders.where((order) {
                // 制限なしの場合は全て表示
                if (_maxDistancePreference == null) return true;

                // レストラン位置情報がない場合は除外
                if (order.restaurant?.latitude == null || order.restaurant?.longitude == null) {
                  print('[DriverDashboard] Order ${order.id} has no restaurant location - excluded');
                  return false;
                }

                // 現在地 → レストランの距離を計算
                final distanceToRestaurant = Geolocator.distanceBetween(
                  _currentLatitude!,
                  _currentLongitude!,
                  order.restaurant!.latitude!,
                  order.restaurant!.longitude!,
                ) / 1000; // km変換

                print('[DriverDashboard] Order ${order.id}: ${distanceToRestaurant.toStringAsFixed(1)}km (max: ${_maxDistancePreference!.toStringAsFixed(0)}km) - ${distanceToRestaurant <= _maxDistancePreference! ? "PASS" : "FILTERED"}');

                return distanceToRestaurant <= _maxDistancePreference!;
              }).toList();

              print('[DriverDashboard] Filtered orders: ${filteredOrders.length}/${orders.length}');

              if (filteredOrders.isEmpty) {
                String message = '現在利用可能な配達はありません';
                if (_maxDistancePreference != null && orders.isNotEmpty) {
                  message = '${_maxDistancePreference!.toStringAsFixed(0)}km以内に利用可能な配達はありません\n設定で距離上限を変更できます';
                }

                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: filteredOrders.map((order) {
                  // 距離計算
                  double? distanceToRestaurant;
                  double? distanceToCustomer;

                  if (_currentLatitude != null && _currentLongitude != null) {
                    // 現在地 → レストラン
                    if (order.restaurant?.latitude != null && order.restaurant?.longitude != null) {
                      distanceToRestaurant = Geolocator.distanceBetween(
                        _currentLatitude!,
                        _currentLongitude!,
                        order.restaurant!.latitude!,
                        order.restaurant!.longitude!,
                      ) / 1000; // km変換
                    }

                    // レストラン → 配達先
                    if (order.restaurant?.latitude != null &&
                        order.restaurant?.longitude != null &&
                        order.deliveryAddress?.latitude != null &&
                        order.deliveryAddress?.longitude != null) {
                      distanceToCustomer = Geolocator.distanceBetween(
                        order.restaurant!.latitude!,
                        order.restaurant!.longitude!,
                        order.deliveryAddress!.latitude!,
                        order.deliveryAddress!.longitude!,
                      ) / 1000; // km変換
                    }
                  }

                  return DriverOrderCard(
                    order: order,
                    distanceToRestaurant: distanceToRestaurant,
                    distanceToCustomer: distanceToCustomer,
                    onAccept: () => _handleAcceptDelivery(order.id),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingIndicator(message: '配達を読み込み中...'),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(availableOrdersProvider);
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(driverOrderHistoryProvider);

    return historyAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.history,
            title: '配達履歴がありません',
            message: '完了した配達がここに表示されます',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverOrderHistoryProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              // 履歴の場合は距離計算しない（既に完了済み）
              return DriverOrderCard(order: order);
            },
          ),
        );
      },
      loading: () => const LoadingIndicator(message: '履歴を読み込み中...'),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () {
          ref.invalidate(driverOrderHistoryProvider);
        },
      ),
    );
  }

  Future<void> _handleToggleOnline(bool isOnline) async {
    // Temporarily disabled Stripe check for testing
    final result = await ref
        .read(driverOnlineStatusProvider.notifier)
        .toggleOnline(isOnline);

    if (mounted) {
      final success = result['success'] as bool;
      final error = result['message'] as ApiError?; // ApiError object or null

      String displayMessage;
      if (success) {
        displayMessage = isOnline ? 'オンラインになりました' : 'オフラインになりました';

        // バックグラウンドサービス: オンライン状態に応じて開始/停止
        if (_backgroundServiceInitialized) {
          if (isOnline) {
            await BackgroundLocationService.start();
            print('[DriverDashboard] Background location service started');
          } else {
            await BackgroundLocationService.stop();
            print('[DriverDashboard] Background location service stopped');
          }
        }
      } else if (error != null) {
        // ApiErrorオブジェクトからメッセージを取得
        if (error.message.contains('Stripe')) {
          // Stripeエラーの場合は具体的なメッセージを表示
          displayMessage = 'Stripe設定を完了してからオンラインにしてください';
        } else {
          displayMessage = error.message;
        }
      } else {
        displayMessage = '状態の変更に失敗しました';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: success ? AppColors.success : Colors.red,
          duration: success ? const Duration(seconds: 2) : const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleAcceptDelivery(int orderId) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'この配達を受諾しますか？',
      message: 'レストランに移動して商品をピックアップしてください。',
      confirmText: '受諾する',
      confirmColor: Colors.green,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(availableOrdersProvider.notifier)
        .acceptDelivery(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '配達を受け付けました' : '受付に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleStartDelivering(int orderId) async {
    // まずPIN入力ダイアログを表示
    final pinVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PickupPinDialog(orderId: orderId),
    );

    if (pinVerified != true) return;

    // PIN確認後、配達開始の確認
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '配達を開始しますか？',
      message: '商品をピックアップし、配達先に向かいます。',
      confirmText: '開始する',
      confirmColor: Colors.orange,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(activeDeliveriesProvider.notifier)
        .startDelivering(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '配達を開始しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleStartDeliveringWithoutPin(int orderId) async {
    // picked_up状態の場合はPIN不要（既に確認済み）
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '配達を開始しますか？',
      message: '配達先に向かいます。',
      confirmText: '開始する',
      confirmColor: Colors.blue,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(activeDeliveriesProvider.notifier)
        .startDelivering(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '配達を開始しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCompleteDelivery(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配達完了'),
        content: const Text('この配達を完了しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('完了'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(activeDeliveriesProvider.notifier)
          .completeDelivery(orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '配達を完了しました' : '完了に失敗しました'),
            backgroundColor: success ? AppColors.success : Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToActiveDelivery(int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DriverActiveDeliveryScreen(orderId: orderId),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.black),
                title: const Text('振込先設定'),
                subtitle: const Text('振込先アカウント'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DriverStripeSetupScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.social_distance, color: Colors.black),
                title: const Text('配達距離の上限'),
                subtitle: Text(
                  _maxDistancePreference == null
                      ? '制限なし'
                      : '${_maxDistancePreference!.toStringAsFixed(0)}km以内',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMaxDistanceDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showMaxDistanceDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMaxDistance = prefs.getDouble('driver_max_distance');

    final options = [
      {'label': '制限なし', 'value': null},
      {'label': '1km以内', 'value': 1.0},
      {'label': '3km以内', 'value': 3.0},
      {'label': '5km以内', 'value': 5.0},
      {'label': '10km以内', 'value': 10.0},
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配達距離の上限'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option['value'] == currentMaxDistance;
            return RadioListTile<double?>(
              title: Text(option['label'] as String),
              value: option['value'] as double?,
              groupValue: currentMaxDistance,
              selected: isSelected,
              activeColor: Colors.black,
              onChanged: (value) async {
                if (value == null) {
                  await prefs.remove('driver_max_distance');
                } else {
                  await prefs.setDouble('driver_max_distance', value);
                }
                if (mounted) {
                  setState(() {
                    _maxDistancePreference = value;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value == null
                          ? '配達距離の制限を解除しました'
                          : '配達距離の上限を${value.toStringAsFixed(0)}kmに設定しました'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  // リフレッシュ
                  ref.invalidate(availableOrdersProvider);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
