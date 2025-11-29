import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/order_provider.dart';
import '../providers/review_provider.dart';
import '../../../shared/models/order_model.dart';
import 'write_review_screen.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('注文詳細'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              _buildStatusCard(context, order),

              // Order Info Card
              _buildOrderInfoCard(context, order),

              // Items Card
              _buildItemsCard(context, order),

              // Delivery Address Card
              if (order.deliveryAddress != null)
                _buildDeliveryAddressCard(context, order),

              // Price Summary Card
              _buildPriceSummaryCard(context, order),

              // Review button for delivered orders
              if (order.status == 'delivered')
                _buildReviewButton(context, ref, order),

              // Cancel button
              if (order.status == 'pending')
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomButton(
                    text: '注文をキャンセル',
                    onPressed: () {
                      _showCancelDialog(context, ref, orderId);
                    },
                    backgroundColor: Colors.red,
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        loading: () => const LoadingIndicator(message: '注文情報を読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(orderDetailProvider(orderId));
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OrderModel order) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    final statusConfig = _getStatusConfig(order.status);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusConfig['color'] as Color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusConfig['label'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '注文番号: ${order.orderNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(order.createdAt),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'レストラン情報',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (order.restaurant != null) ...[
              _buildInfoRow(
                icon: Icons.restaurant,
                label: order.restaurant!.name,
              ),
              if (order.restaurant!.phone != null)
                _buildInfoRow(
                  icon: Icons.phone,
                  label: order.restaurant!.phone!,
                ),
              if (order.restaurant!.address != null)
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: order.restaurant!.address!,
                ),
            ],
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.payment,
              label: order.paymentMethod == 'card' ? 'カード決済' : '現金払い',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItem?.name ?? 'メニューアイテム',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.selectedOptions != null &&
                                  item.selectedOptions!.isNotEmpty)
                                ...item.selectedOptions!.map((opt) => Text(
                                      '  + ${opt.name}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    )),
                              if (item.specialRequest != null)
                                Text(
                                  '  リクエスト: ${item.specialRequest}',
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
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '¥${item.totalPrice.toInt()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '配達先住所',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_on,
              label: order.deliveryAddress!.fullAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard(BuildContext context, OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '料金詳細',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow('小計', order.subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('配送料', order.deliveryFee),
            const SizedBox(height: 8),
            _buildPriceRow('消費税', order.tax),
            if (order.discount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('割引', -order.discount, color: Colors.red),
            ],
            const Divider(height: 24),
            _buildPriceRow(
              '合計',
              order.total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text(
          '¥${amount.toInt()}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isTotal ? AppColors.primaryGreen : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {'label': '保留中', 'color': Colors.orange};
      case 'accepted':
        return {'label': '受付済み', 'color': Colors.blue};
      case 'preparing':
        return {'label': '準備中', 'color': Colors.blue};
      case 'ready':
        return {'label': '準備完了', 'color': Colors.purple};
      case 'picked_up':
        return {'label': 'ピックアップ済み', 'color': Colors.indigo};
      case 'delivering':
        return {'label': '配達中', 'color': AppColors.primaryGreen};
      case 'delivered':
        return {'label': '配達完了', 'color': AppColors.success};
      case 'cancelled':
        return {'label': 'キャンセル', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  Widget _buildReviewButton(BuildContext context, WidgetRef ref, OrderModel order) {
    final canReviewAsync = ref.watch(canReviewProvider(order.id));

    return canReviewAsync.when(
      data: (canReviewResponse) {
        if (canReviewResponse.hasReview) {
          // Already reviewed - show the existing review
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rate_review, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      const Text(
                        'レビュー投稿済み',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (canReviewResponse.review != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < canReviewResponse.review!.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    if (canReviewResponse.review!.comment != null &&
                        canReviewResponse.review!.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        canReviewResponse.review!.comment!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        }

        if (canReviewResponse.canReview) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: 'レビューを書く',
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => WriteReviewScreen(
                      orderId: order.id,
                      restaurantName: order.restaurant?.name ?? 'レストラン',
                    ),
                  ),
                );

                if (result == true) {
                  ref.invalidate(canReviewProvider(order.id));
                }
              },
              backgroundColor: AppColors.primaryGreen,
              icon: Icons.rate_review,
            ),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, int orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('注文をキャンセル'),
        content: const Text('この注文をキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              final success = await ref.read(orderDetailProvider(orderId).notifier).cancelOrder();

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('注文をキャンセルしました'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('キャンセルに失敗しました'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'はい、キャンセル',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
