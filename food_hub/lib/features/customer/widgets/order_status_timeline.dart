import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Order status definition
class OrderStatusInfo {
  final String status;
  final String title;
  final IconData icon;
  final int order;

  const OrderStatusInfo({
    required this.status,
    required this.title,
    required this.icon,
    required this.order,
  });
}

/// All possible order statuses
const List<OrderStatusInfo> orderStatuses = [
  OrderStatusInfo(
    status: 'pending',
    title: '注文受付',
    icon: Icons.receipt_long,
    order: 1,
  ),
  OrderStatusInfo(
    status: 'accepted',
    title: '店舗確認済み',
    icon: Icons.check_circle_outline,
    order: 2,
  ),
  OrderStatusInfo(
    status: 'preparing',
    title: '調理中',
    icon: Icons.restaurant,
    order: 3,
  ),
  OrderStatusInfo(
    status: 'ready',
    title: '配達準備完了',
    icon: Icons.takeout_dining,
    order: 4,
  ),
  OrderStatusInfo(
    status: 'picked_up',
    title: '配達員が受け取り',
    icon: Icons.local_shipping,
    order: 5,
  ),
  OrderStatusInfo(
    status: 'delivering',
    title: '配達中',
    icon: Icons.delivery_dining,
    order: 6,
  ),
  OrderStatusInfo(
    status: 'delivered',
    title: '配達完了',
    icon: Icons.home,
    order: 7,
  ),
];

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  final DateTime? orderedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    this.orderedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  int _getStatusOrder(String status) {
    final statusInfo = orderStatuses.where((s) => s.status == status).firstOrNull;
    return statusInfo?.order ?? 0;
  }

  bool _isStatusCompleted(OrderStatusInfo statusInfo) {
    if (currentStatus == 'cancelled') {
      return false;
    }
    return _getStatusOrder(currentStatus) >= statusInfo.order;
  }

  bool _isStatusCurrent(OrderStatusInfo statusInfo) {
    return statusInfo.status == currentStatus;
  }

  String? _getTimeForStatus(OrderStatusInfo statusInfo) {
    DateTime? time;
    switch (statusInfo.status) {
      case 'pending':
        time = orderedAt;
        break;
      case 'accepted':
      case 'preparing':
      case 'ready':
        time = acceptedAt;
        break;
      case 'picked_up':
      case 'delivering':
        time = pickedUpAt;
        break;
      case 'delivered':
        time = deliveredAt;
        break;
    }

    if (time == null) return null;

    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Show cancelled state
    if (currentStatus == 'cancelled') {
      return _buildCancelledState();
    }

    return Column(
      children: orderStatuses.asMap().entries.map((entry) {
        final index = entry.key;
        final statusInfo = entry.value;
        final isCompleted = _isStatusCompleted(statusInfo);
        final isCurrent = _isStatusCurrent(statusInfo);
        final isLast = index == orderStatuses.length - 1;
        final time = _getTimeForStatus(statusInfo);

        return _TimelineItem(
          statusInfo: statusInfo,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          isLast: isLast,
          time: isCompleted ? time : null,
        );
      }).toList(),
    );
  }

  Widget _buildCancelledState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red[400],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'キャンセル済み',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                if (cancelledAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'キャンセル日時: ${_formatDateTime(cancelledAt!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[300],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineItem extends StatelessWidget {
  final OrderStatusInfo statusInfo;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final String? time;

  const _TimelineItem({
    required this.statusInfo,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Circle indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.black
                        : isCurrent
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.grey[200],
                    border: isCurrent && !isCompleted
                        ? Border.all(
                            color: Colors.black,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    statusInfo.icon,
                    size: 18,
                    color: isCompleted
                        ? Colors.white
                        : isCurrent
                            ? Colors.black
                            : Colors.grey[400],
                  ),
                ),

                // Line connector
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted ? Colors.black : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        statusInfo.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCompleted || isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCompleted || isCurrent
                              ? AppColors.textPrimary
                              : Colors.grey[400],
                        ),
                      ),
                      if (isCurrent && !isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '現在',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
