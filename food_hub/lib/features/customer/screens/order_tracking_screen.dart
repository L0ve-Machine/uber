import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../shared/constants/order_status_labels.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/order_tracking_map.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _refreshTimer;
  final SocketService _socketService = SocketService();
  StreamSubscription? _locationSubscription;

  // リアルタイム配達員位置（Socket.IOから更新）
  double? _realtimeDriverLat;
  double? _realtimeDriverLng;

  @override
  void initState() {
    super.initState();

    // Socket.IO接続
    _socketService.connect();

    // 配達員位置更新をリッスン
    _locationSubscription = _socketService.driverLocationStream.listen((update) {
      print('[OrderTrackingScreen] Driver location update: ${update.driverId}');
      setState(() {
        _realtimeDriverLat = update.latitude;
        _realtimeDriverLng = update.longitude;
      });
    });

    // Auto-refresh every 30 seconds (fallback for non-realtime data)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(orderDetailProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('注文追跡'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(orderDetailProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                '注文情報の読み込みに失敗しました',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: '再試行',
                onPressed: () {
                  ref.invalidate(orderDetailProvider(widget.orderId));
                },
                width: 120,
              ),
            ],
          ),
        ),
        data: (order) {
          final isActive = !['delivered', 'cancelled'].contains(order.status);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderDetailProvider(widget.orderId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '注文番号',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.orderNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              _buildStatusBadge(order.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order.restaurant?.name ?? '-',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Map (only if order has location data)
                  if (order.deliveryAddress?.latitude != null &&
                      order.deliveryAddress?.longitude != null &&
                      order.restaurant?.latitude != null &&
                      order.restaurant?.longitude != null) ...[
                    const Text(
                      '配達状況',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OrderTrackingMap(
                      driverLatitude: _realtimeDriverLat,
                      driverLongitude: _realtimeDriverLng,
                      restaurantLatitude: order.restaurant!.latitude!,
                      restaurantLongitude: order.restaurant!.longitude!,
                      deliveryLatitude: order.deliveryAddress!.latitude!,
                      deliveryLongitude: order.deliveryAddress!.longitude!,
                      showDriverLocation: isActive &&
                          order.driverId != null &&
                          _realtimeDriverLat != null &&
                          _realtimeDriverLng != null,
                      orderStatus: order.status,
                      hasDriver: order.driverId != null,
                      restaurantName: order.restaurant?.name,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Status Timeline
                  const Text(
                    'ステータス',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: OrderStatusTimeline(
                        currentStatus: order.status,
                        orderedAt: order.createdAt,
                        acceptedAt: order.acceptedAt,
                        pickedUpAt: order.pickedUpAt,
                        deliveredAt: order.deliveredAt,
                        cancelledAt: order.cancelledAt,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Address
                  const Text(
                    '配達先',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              order.deliveryAddress?.fullAddress ?? '-',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order Items
                  const Text(
                    '注文内容',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        if (order.items != null)
                          ...order.items!.map((item) {
                            return ListTile(
                              dense: true,
                              title: Text(item.menuItem?.name ?? '商品 #${item.menuItemId}'),
                              subtitle: item.selectedOptions != null &&
                                      item.selectedOptions!.isNotEmpty
                                  ? Text(
                                      item.selectedOptions!.map((o) => o.name).join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : null,
                              trailing: Text(
                                '¥${item.totalPrice.toInt()} x${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildPriceRow('小計', order.subtotal),
                              const SizedBox(height: 8),
                              _buildPriceRow('配送料', order.deliveryFee),
                              const SizedBox(height: 8),
                              _buildPriceRow('消費税', order.tax),
                              if (order.discount > 0) ...[
                                const SizedBox(height: 8),
                                _buildPriceRow('割引', -order.discount,
                                    valueColor: Colors.red),
                              ],
                              const Divider(height: 24),
                              _buildPriceRow('合計', order.total, isTotal: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Special Instructions
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    const Text(
                      '特別リクエスト',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                order.specialInstructions!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cancel Button (only for pending orders)
                  if (order.status == 'pending') ...[
                    OutlinedButton(
                      onPressed: () => _showCancelDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('注文をキャンセル'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Auto-refresh indicator
                  if (isActive)
                    Center(
                      child: Text(
                        '30秒ごとに自動更新されます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        // 「確認待ち」→「支払い済み」に変更し、色を緑色に
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = OrderStatusLabels.customer[status] ?? '支払い済み';
        break;
      case 'accepted':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        text = OrderStatusLabels.customer[status] ?? '確認済み';
        break;
      case 'preparing':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        text = OrderStatusLabels.customer[status] ?? '調理中';
        break;
      case 'ready':
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
        text = OrderStatusLabels.customer[status] ?? '準備完了';
        break;
      case 'picked_up':
        backgroundColor = Colors.indigo[100]!;
        textColor = Colors.indigo[800]!;
        text = OrderStatusLabels.customer[status] ?? '配達中';
        break;
      case 'delivering':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = OrderStatusLabels.customer[status] ?? '配達中';
        break;
      case 'delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = OrderStatusLabels.customer[status] ?? '配達完了';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = OrderStatusLabels.customer[status] ?? 'キャンセル';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isTotal = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '¥${amount.toInt()}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注文をキャンセル'),
        content: const Text('この注文をキャンセルしますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('戻る'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(orderDetailProvider(widget.orderId).notifier)
                  .cancelOrder();

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('注文をキャンセルしました'),
                    backgroundColor: Colors.green,
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
            },
            child: const Text(
              'キャンセル',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
