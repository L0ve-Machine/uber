import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/order_model.dart';

class DriverOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onStartDelivering;
  final VoidCallback? onCompleteDelivery;

  const DriverOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onStartDelivering,
    this.onCompleteDelivery,
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

              // Restaurant info
              if (order.restaurant != null) ...[
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.restaurant!.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (order.restaurant!.address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          order.restaurant!.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],

              // Delivery address
              if (order.deliveryAddress != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${order.deliveryAddress!.addressLine}, ${order.deliveryAddress!.city}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Items count
              if (order.items != null && order.items!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${order.items!.length}点の商品',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Earnings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '配達報酬',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    '¥${order.deliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
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
      case 'ready':
        color = Colors.orange;
        label = '受取可能';
        break;
      case 'picked_up':
        color = Colors.blue;
        label = '受取済み';
        break;
      case 'delivering':
        color = Colors.purple;
        label = '配達中';
        break;
      case 'delivered':
        color = AppColors.success;
        label = '配達完了';
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
    return order.status == 'ready' ||
           order.status == 'picked_up' ||
           order.status == 'delivering';
  }

  Widget _buildActionButtons() {
    switch (order.status) {
      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check),
            label: const Text('配達を受ける'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        );
      case 'picked_up':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStartDelivering,
            icon: const Icon(Icons.directions_bike),
            label: const Text('配達開始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      case 'delivering':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCompleteDelivery,
            icon: const Icon(Icons.check_circle),
            label: const Text('配達完了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
