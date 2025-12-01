import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/stripe_payment_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/models/address_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/coupon_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _specialInstructionsController = TextEditingController();
  final _couponController = TextEditingController();
  final StripePaymentService _stripeService = StripePaymentService();
  String _paymentMethod = 'cash';
  bool _isPlacingOrder = false;
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _stripeService.initialize();
  }

  @override
  void dispose() {
    _specialInstructionsController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配達先を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('カートが空です'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final restaurantId = cartItems.first.menuItem.restaurantId;

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final result = await ref.read(createOrderProvider.notifier).placeOrder(
            restaurantId: restaurantId,
            deliveryAddressId: _selectedAddress!.id,
            paymentMethod: _paymentMethod,
            specialInstructions: _specialInstructionsController.text.isNotEmpty
                ? _specialInstructionsController.text
                : null,
          );

      if (!mounted) return;

      await result.when(
        success: (order) async {
          if (_paymentMethod == 'card') {
            try {
              final storageService = ref.read(storageServiceProvider);
              final token = await storageService.getAuthToken();

              if (token == null) {
                throw Exception('認証トークンが見つかりません');
              }

              final paymentSuccess = await _stripeService.processPayment(
                orderId: order.id,
                token: token,
              );

              if (!paymentSuccess) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('決済がキャンセルされました'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              print('[Checkout] Payment successful for order: ${order.id}');
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('決済に失敗しました: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/customer/order-confirmation',
              arguments: order,
            );
          }
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('注文に失敗しました: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[Checkout] ========== build() START ==========');

    final cartItems = ref.watch(cartProvider);
    print('[Checkout] Got cartItems: ${cartItems.length}');

    final cartNotifier = ref.watch(cartProvider.notifier);
    print('[Checkout] Got cartNotifier');

    if (cartItems.isEmpty) {
      print('[Checkout] Cart is empty, showing empty state');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('チェックアウト'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('カートが空です')),
      );
    }

    print('[Checkout] Cart is not empty, building full UI');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('チェックアウト'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(builder: (context) {
              print('[Checkout] Rendering Address Section');
              return _buildSection(
                title: '配達先住所',
                child: _buildAddressSelector(),
              );
            }),

            const SizedBox(height: 16),

            // Order Items
            _buildSection(
              title: '注文内容',
              child: _buildOrderItems(cartItems),
            ),

            const SizedBox(height: 16),

            // Coupon
            _buildSection(
              title: 'クーポン',
              child: _buildCoupon(),
            ),

            const SizedBox(height: 16),

            // Special Instructions
            _buildSection(
              title: '特別リクエスト（オプション）',
              child: TextField(
                controller: _specialInstructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'アレルギー情報、配達時の注意事項など',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method
            _buildSection(
              title: 'お支払い方法',
              child: _buildPaymentMethod(),
            ),

            const SizedBox(height: 16),

            // Price Summary
            _buildSection(
              title: '料金詳細',
              child: _buildPriceSummary(cartNotifier),
            ),

            const SizedBox(height: 24),

            // Place Order Button
            Consumer(
              builder: (context, ref, _) {
                final couponState = ref.watch(appliedCouponProvider);
                final total = cartNotifier.total - couponState.discount;
                return CustomButton(
                  text: '注文を確定する（¥${total.toInt()}）',
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  isLoading: _isPlacingOrder,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildAddressSelector() {
    print('[Checkout] _buildAddressSelector() called');
    print('[Checkout] _selectedAddress: $_selectedAddress');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('テスト: 住所セクション'),
      ),
    );
  }

  Widget _buildOrderItems(List cartItems) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            title: Text(item.menuItem.name),
            subtitle: Text('x${item.quantity}'),
            trailing: Text(
              '¥${item.totalPrice.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoupon() {
    final couponState = ref.watch(appliedCouponProvider);

    if (couponState.coupon != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      couponState.coupon!.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('-¥${couponState.discount}'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(appliedCouponProvider.notifier).removeCoupon();
                  _couponController.clear();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: const InputDecoration(
                  hintText: 'クーポンコードを入力',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                if (_couponController.text.trim().isEmpty) return;

                final cartNotifier = ref.read(cartProvider.notifier);
                final success = await ref
                    .read(appliedCouponProvider.notifier)
                    .applyCoupon(
                      code: _couponController.text.trim(),
                      subtotal: cartNotifier.subtotal,
                    );

                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('クーポンが適用されました'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: const Row(
              children: [
                Icon(Icons.money),
                SizedBox(width: 12),
                Text('代金引換'),
              ],
            ),
            activeColor: Colors.black,
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: const Row(
              children: [
                Icon(Icons.credit_card),
                SizedBox(width: 12),
                Text('クレジットカード'),
              ],
            ),
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Cart cartNotifier) {
    final couponState = ref.watch(appliedCouponProvider);
    final discount = couponState.discount.toDouble();
    final total = cartNotifier.total - discount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('小計', cartNotifier.subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('配送料', cartNotifier.deliveryFee),
            const SizedBox(height: 8),
            _buildPriceRow('サービス料（15%）', cartNotifier.serviceFee),
            const SizedBox(height: 8),
            _buildPriceRow('消費税（10%）', cartNotifier.tax),
            if (discount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('クーポン割引', -discount, color: Colors.red),
            ],
            const Divider(height: 24),
            _buildPriceRow('合計', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? (isTotal ? Colors.black : Colors.grey[700]),
          ),
        ),
        Text(
          '¥${amount.toInt()}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
