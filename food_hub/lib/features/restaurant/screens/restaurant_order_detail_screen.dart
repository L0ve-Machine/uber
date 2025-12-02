import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../providers/restaurant_order_provider.dart';

class RestaurantOrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const RestaurantOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(restaurantOrderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('注文詳細'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '注文 #${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('yyyy年MM月dd日 HH:mm').format(order.createdAt),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '配達先情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (order.deliveryAddress != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.deliveryAddress!.fullAddress,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Order items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '注文内容',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (order.items != null)
                        ...order.items!.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.menuItem?.name ?? 'メニュー',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
                                      Text(
                                        item.selectedOptions!.map((o) => o.name).join(', '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    if (item.specialRequest != null && item.specialRequest!.isNotEmpty)
                                      Text(
                                        '備考: ${item.specialRequest}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '¥${item.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )),
                      const Divider(),
                      // Summary
                      _buildSummaryRow('小計', '¥${order.subtotal.toStringAsFixed(0)}'),
                      _buildSummaryRow('配達料', '¥${order.deliveryFee.toStringAsFixed(0)}'),
                      _buildSummaryRow('税', '¥${order.tax.toStringAsFixed(0)}'),
                      if (order.discount > 0)
                        _buildSummaryRow('割引', '-¥${order.discount.toStringAsFixed(0)}', isDiscount: true),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '合計',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '¥${order.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Special instructions
              if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '特別な指示',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(order.specialInstructions!),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Pickup PIN (表示: readyステータス時)
              if (order.status == 'ready' && order.pickupPin != null) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'ピックアップPIN',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          order.pickupPin!,
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 12,
                            fontFamily: 'monospace',
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                '配達員にこのPINを伝えてください',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons
              _buildActionButtons(context, ref, order.status),
              const SizedBox(height: 24),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(message: '注文詳細を読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(restaurantOrderDetailProvider(orderId));
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = '新規';
        break;
      case 'accepted':
        color = Colors.blue;
        label = '受付済み';
        break;
      case 'preparing':
        color = Colors.purple;
        label = '準備中';
        break;
      case 'ready':
        color = AppColors.success;
        label = '準備完了';
        break;
      case 'picked_up':
        color = Colors.teal;
        label = '配達中';
        break;
      case 'delivered':
        color = Colors.grey;
        label = '配達完了';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'キャンセル';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, String status) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleReject(context, ref),
                icon: const Icon(Icons.close),
                label: const Text('拒否'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleAccept(context, ref),
                icon: const Icon(Icons.check),
                label: const Text('受付'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleStartPreparing(context, ref),
            icon: const Icon(Icons.restaurant),
            label: const Text('調理開始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleMarkReady(context, ref),
            icon: const Icon(Icons.check_circle),
            label: const Text('準備完了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '注文を受け付けますか？',
      message: 'この注文を受け付けると、調理を開始する必要があります。',
      confirmText: '受け付ける',
      confirmColor: Colors.green,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(restaurantOrderDetailProvider(orderId).notifier)
        .accept();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '注文を受け付けました' : '注文の受付に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
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
          .read(restaurantOrderDetailProvider(orderId).notifier)
          .reject(reason: reasonController.text.isNotEmpty ? reasonController.text : null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '注文を拒否しました' : '注文の拒否に失敗しました'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _handleStartPreparing(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '調理を開始しますか？',
      message: 'この注文の調理を開始します。',
      confirmText: '開始する',
      confirmColor: Colors.purple,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(restaurantOrderDetailProvider(orderId).notifier)
        .startPreparing();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '調理を開始しました' : '状態の更新に失敗しました'),
          backgroundColor: success ? Colors.purple : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleMarkReady(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '準備完了にしますか？',
      message: '商品の準備が完了し、配達員のピックアップを待つ状態にします。',
      confirmText: '完了',
      confirmColor: Colors.green,
    );

    if (confirmed != true) return;

    final success = await ref
        .read(restaurantOrderDetailProvider(orderId).notifier)
        .markReady();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '準備完了にしました' : '状態の更新に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }
}
