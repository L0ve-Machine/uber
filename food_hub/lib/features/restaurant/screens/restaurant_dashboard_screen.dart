import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/restaurant_order_provider.dart';
import '../providers/restaurant_menu_provider.dart';
import '../widgets/restaurant_order_card.dart';
import 'restaurant_order_detail_screen.dart';
import 'restaurant_menu_list_screen.dart';
import 'restaurant_stripe_setup_screen.dart';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState
    extends ConsumerState<RestaurantDashboardScreen> {
  String? _selectedStatus;
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    String _getTitle() {
      switch (_currentIndex) {
        case 0:
          return '注文管理';
        case 1:
          return 'メニュー管理';
        case 2:
          return '設定';
        default:
          return 'FoodHub';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_currentIndex != 2)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_currentIndex == 0) {
                  ref.invalidate(restaurantOrdersProvider(status: _selectedStatus));
                  ref.invalidate(restaurantStatsProvider());
                } else {
                  ref.invalidate(restaurantMenuProvider());
                }
              },
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
      body: _currentIndex == 0
          ? _buildOrdersTab()
          : _currentIndex == 1
              ? const RestaurantMenuListScreen()
              : _buildSettingsTab(),
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
            icon: Icon(Icons.receipt_long),
            label: '注文',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'メニュー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/restaurant/menu/add');
              },
              backgroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('メニュー追加'),
            )
          : null,
    );
  }

  Widget _buildOrdersTab() {
    final user = ref.watch(authProvider).value;
    final statsAsync = ref.watch(restaurantStatsProvider());
    final ordersAsync = ref.watch(restaurantOrdersProvider(status: _selectedStatus));

    return Column(
      children: [
        // Stats summary
        statsAsync.when(
          data: (stats) => Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.receipt,
                        label: '本日の注文',
                        value: '${stats.totalOrders}件',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.attach_money,
                        label: '本日の売上',
                        value: '¥${stats.totalRevenue.toStringAsFixed(0)}',
                        color: Colors.grey[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Status filter
        _buildStatusFilter(),

        // Orders list
        Expanded(
          child: ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: '注文がありません',
                  message: _selectedStatus != null
                      ? 'この状態の注文はありません'
                      : '新しい注文が入るとここに表示されます',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(restaurantOrdersProvider(status: _selectedStatus));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return RestaurantOrderCard(
                      order: order,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RestaurantOrderDetailScreen(
                              orderId: order.id,
                            ),
                          ),
                        );
                      },
                      onAccept: () => _handleAcceptOrder(order.id),
                      onReject: () => _showRejectDialog(order.id),
                      onStartPreparing: () => _handleStartPreparing(order.id),
                      onMarkReady: () => _handleMarkReady(order.id),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingIndicator(message: '注文を読み込み中...'),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(restaurantOrdersProvider(status: _selectedStatus));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    final statuses = {
      null: 'すべて',
      'pending': '新規',
      'accepted': '受付済み',
      'preparing': '準備中',
      'ready': '準備完了',
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: statuses.entries.map((entry) {
          final isSelected = _selectedStatus == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? entry.key : null;
                });
                ref.read(restaurantOrdersProvider(status: _selectedStatus).notifier)
                    .filterByStatus(_selectedStatus);
              },
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? Colors.black : AppColors.gray300),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleAcceptOrder(int orderId) async {
    final success = await ref
        .read(restaurantOrdersProvider(status: _selectedStatus).notifier)
        .acceptOrder(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '注文を受け付けました' : '注文の受付に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  Future<void> _showRejectDialog(int orderId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注文を拒否'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('この注文を拒否しますか？'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '理由（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('拒否'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(restaurantOrdersProvider(status: _selectedStatus).notifier)
          .rejectOrder(orderId, reason: reasonController.text.isNotEmpty ? reasonController.text : null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '注文を拒否しました' : '注文の拒否に失敗しました'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleStartPreparing(int orderId) async {
    final success = await ref
        .read(restaurantOrdersProvider(status: _selectedStatus).notifier)
        .startPreparing(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '調理を開始しました' : '状態の更新に失敗しました'),
          backgroundColor: success ? Colors.purple : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleMarkReady(int orderId) async {
    final success = await ref
        .read(restaurantOrdersProvider(status: _selectedStatus).notifier)
        .markReady(orderId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '準備完了にしました' : '状態の更新に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
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
                      builder: (context) => const RestaurantStripeSetupScreen(),
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
