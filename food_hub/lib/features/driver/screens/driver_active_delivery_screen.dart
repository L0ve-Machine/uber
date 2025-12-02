import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../providers/driver_provider.dart';
import '../widgets/delivery_status_stepper.dart';
import '../widgets/pickup_pin_dialog.dart';

class DriverActiveDeliveryScreen extends ConsumerWidget {
  final int orderId;

  const DriverActiveDeliveryScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('配達詳細'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: activeDeliveriesAsync.when(
        data: (orders) {
          final order = orders.where((o) => o.id == orderId).firstOrNull;

          if (order == null) {
            return const Center(child: Text('配達が見つかりません'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status stepper
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '¥${order.deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DeliveryStatusStepper(currentStatus: order.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Restaurant info
                if (order.restaurant != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.restaurant, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                '受取場所',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.restaurant!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (order.restaurant!.address != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              order.restaurant!.address!,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                          if (order.restaurant!.phone != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _callPhone(order.restaurant!.phone!),
                                    icon: const Icon(Icons.phone),
                                    label: const Text('電話する'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openMaps(
                                      order.restaurant!.address ?? '',
                                    ),
                                    icon: const Icon(Icons.navigation),
                                    label: const Text('ナビ'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
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

                // Delivery address
                if (order.deliveryAddress != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text(
                                '配達先',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.deliveryAddress!.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.deliveryAddress!.fullAddress,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openMaps(
                                order.deliveryAddress!.fullAddress,
                              ),
                              icon: const Icon(Icons.navigation),
                              label: const Text('ナビ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Order items
                if (order.items != null && order.items!.isNotEmpty)
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
                          ...order.items!.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
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
                                  child: Text(item.menuItem?.name ?? 'メニュー'),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Action button
                _buildActionButton(context, ref, order.status),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: '配達情報を読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(activeDeliveriesProvider);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, String status) {
    switch (status) {
      case 'ready':
        // Driver has accepted, needs to verify PIN at restaurant
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleStartDelivering(context, ref),
            icon: const Icon(Icons.pin),
            label: const Text('受け取り確認'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      case 'picked_up':
        // PIN already verified, just need confirmation to start delivery
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleStartDeliveryWithoutPin(context, ref),
            icon: const Icon(Icons.directions_bike),
            label: const Text('配達開始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      case 'delivering':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleCompleteDelivery(context, ref),
            icon: const Icon(Icons.check_circle),
            label: const Text('配達完了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleStartDelivering(BuildContext context, WidgetRef ref) async {
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '配達を開始しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleStartDeliveryWithoutPin(BuildContext context, WidgetRef ref) async {
    // PIN already verified, just show confirmation
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '配達を開始しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.blue : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleCompleteDelivery(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '配達完了しましたか？',
      message: '顧客に商品を渡し、配達を完了します。',
      confirmText: '完了',
      confirmColor: Colors.green,
    );

    if (confirmed == true) {
      final success = await ref
          .read(activeDeliveriesProvider.notifier)
          .completeDelivery(orderId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '配達を完了しました' : '完了に失敗しました'),
            backgroundColor: success ? AppColors.success : Colors.red,
          ),
        );
        if (success) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
