import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../widgets/driver_order_card.dart';
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
                    ...activeOrders.map((order) => DriverOrderCard(
                      order: order,
                      onTap: () => _navigateToActiveDelivery(order.id),
                      onStartDelivering: () => _handleStartDelivering(order.id),
                      onCompleteDelivery: () => _handleCompleteDelivery(order.id),
                    )),
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
              if (orders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '現在利用可能な配達はありません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: orders.map((order) => DriverOrderCard(
                  order: order,
                  onAccept: () => _handleAcceptDelivery(order.id),
                )).toList(),
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
    // オフラインにする場合は通常処理
    if (!isOnline) {
      final success = await ref
          .read(driverOnlineStatusProvider.notifier)
          .toggleOnline(isOnline);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'オフラインになりました' : '状態の変更に失敗しました'),
            backgroundColor: success ? AppColors.success : Colors.red,
          ),
        );
      }
      return;
    }

    // オンラインにする場合、Stripe設定チェック
    final driverAsync = ref.read(driverProfileProvider);
    final driver = driverAsync.valueOrNull;

    if (driver == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配達員情報の取得に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!driver.isStripeFullySetup) {
      // Stripe設定が未完了の場合、ダイアログ表示
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stripe設定が必要です'),
            content: Text(
              (driver.stripeSetupIssue ?? 'Stripe設定が完了していません。') +
                  '\n\n報酬を受け取るためには、Stripe登録を完了してください。',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverStripeSetupScreen(),
                    ),
                  );
                },
                child: const Text('設定画面へ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Stripe設定完了済み、通常処理
    final success = await ref
        .read(driverOnlineStatusProvider.notifier)
        .toggleOnline(isOnline);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'オンラインになりました' : '状態の変更に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAcceptDelivery(int orderId) async {
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
                subtitle: const Text('Stripe Connect'),
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
      ],
    );
  }
}
