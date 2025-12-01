import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/order_provider.dart';
import '../../../shared/models/order_model.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderHistoryProvider(status: _selectedStatus));

    return Column(
        children: [
          // Status filter
          _buildStatusFilter(),

          // Order list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: '注文履歴がありません',
                    message: _selectedStatus != null
                        ? 'このステータスの注文がありません'
                        : 'まだ注文をしていません',
                    action: _selectedStatus == null
                        ? CustomButton(
                            text: 'レストランを探す',
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            width: 200,
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(orderHistoryProvider(status: _selectedStatus).notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderCard(
                        order: order,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/customer/order-detail',
                            arguments: order.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: '注文履歴を読み込み中...'),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(orderHistoryProvider(status: _selectedStatus));
                },
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildStatusFilter() {
    final statuses = {
      null: 'すべて',
      'pending': '支払い済み',
      'accepted': '受付済み',
      'preparing': '準備中',
      'ready': '準備完了',
      'picked_up': 'ピックアップ済み',
      'delivering': '配達中',
      'delivered': '配達完了',
      'cancelled': 'キャンセル',
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
              },
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order number and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),

              // Restaurant info
              if (order.restaurant != null) ...[
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.restaurant!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Date
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items count
              if (order.items != null) ...[
                Text(
                  '${order.items!.length}品 - 合計 ¥${order.total.toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  '合計 ¥${order.total.toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  // Track button for active deliveries
                  if (['picked_up', 'delivering'].contains(order.status))
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.location_on, size: 18),
                        label: const Text('追跡'),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/customer/order-tracking/${order.id}',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                    ),

                  // Spacer between buttons
                  if (['picked_up', 'delivering'].contains(order.status) && order.status == 'pending')
                    const SizedBox(width: 8),

                  // Cancel button for pending orders
                  if (order.status == 'pending')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showCancelDialog(context, order.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('キャンセル'),
                      ),
                    ),

                  // Empty spacer if no action buttons
                  if (!['picked_up', 'delivering', 'pending'].contains(order.status))
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig['color'] as Color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusConfig['label'] as String,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {'label': '支払い済み', 'color': Colors.green};
      case 'accepted':
        return {'label': '受付済み', 'color': Colors.blue};
      case 'preparing':
        return {'label': '準備中', 'color': Colors.blue};
      case 'ready':
        return {'label': '準備完了', 'color': Colors.purple};
      case 'picked_up':
        return {'label': 'ピックアップ済み', 'color': Colors.indigo};
      case 'delivering':
        return {'label': '配達中', 'color': Colors.black};
      case 'delivered':
        return {'label': '配達完了', 'color': AppColors.success};
      case 'cancelled':
        return {'label': 'キャンセル', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  void _showCancelDialog(BuildContext context, int orderId) {
    // Will be implemented in order detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('注文詳細画面からキャンセルできます'),
      ),
    );
  }
}
