import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order_model.dart';

class RestaurantOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;

  const RestaurantOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onStartPreparing,
    this.onMarkReady,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '注文 #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 12),

              // Customer info
              if (order.deliveryAddress != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${order.deliveryAddress!.addressLine}, ${order.deliveryAddress!.city}',
                        style: TextStyle(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Order time
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items summary
              if (order.items != null && order.items!.isNotEmpty) ...[
                Text(
                  '${order.items!.length}点の商品',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ...order.items!.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '• ${item.menuItem?.name ?? 'メニュー'} x${item.quantity}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                if (order.items!.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '他 ${order.items!.length - 3} 点...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('合計', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '¥${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              // Action buttons based on status
              if (_shouldShowActions()) ...[
                const Divider(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (order.status) {
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
        label = order.status;
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

  bool _shouldShowActions() {
    return order.status == 'pending' ||
           order.status == 'accepted' ||
           order.status == 'preparing';
  }

  Widget _buildActionButtons() {
    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('拒否'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('受付'),
              ),
            ),
          ],
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStartPreparing,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('調理開始'),
          ),
        );
      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onMarkReady,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('準備完了'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
