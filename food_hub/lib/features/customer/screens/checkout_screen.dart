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
  String _paymentMethod = 'card';  // Stripe決済のみ対応
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
          // Stripe決済処理（常に実行）
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
            Text('配達先住所', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 8),
            _buildAddressSelector(),
            const SizedBox(height: 16),
            Text('注文内容', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 8),
            _buildOrderItems(cartItems),
            const SizedBox(height: 16),
            Text('料金詳細', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 8),
            _buildPriceSummary(cartNotifier),
            const SizedBox(height: 24),
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
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).pushNamed(
            '/customer/addresses/select',
            arguments: _selectedAddress,
          );
          if (result != null && result is AddressModel) {
            setState(() {
              _selectedAddress = result;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _selectedAddress == null
              ? Row(
                  children: [
                    const Icon(Icons.add_location, color: Colors.black),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('配達先を選択')),
                    const Icon(Icons.chevron_right),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAddress!.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress!.fullAddress,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Text('変更', style: TextStyle(color: Colors.black)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildOrderItems(List cartItems) {
    print('[Checkout] _buildOrderItems() called with ${cartItems.length} items');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: cartItems.map((item) {
            print('[Checkout] Mapping item: ${item.menuItem.name}');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menuItem.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('x${item.quantity}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('¥${item.totalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCoupon() {
    print('[Checkout] _buildCoupon() called');
    final couponState = ref.watch(appliedCouponProvider);
    print('[Checkout] couponState loaded: ${couponState.coupon}');

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

  // 未使用のため削除: Stripe決済のみ対応

  Widget _buildPriceSummary(Cart cartNotifier) {
    print('[Checkout] _buildPriceSummary() called');
    print('[Checkout] subtotal type: ${cartNotifier.subtotal.runtimeType}, value: ${cartNotifier.subtotal}');
    print('[Checkout] deliveryFee type: ${cartNotifier.deliveryFee.runtimeType}, value: ${cartNotifier.deliveryFee}');
    print('[Checkout] serviceFee type: ${cartNotifier.serviceFee.runtimeType}, value: ${cartNotifier.serviceFee}');
    print('[Checkout] tax type: ${cartNotifier.tax.runtimeType}, value: ${cartNotifier.tax}');
    print('[Checkout] total type: ${cartNotifier.total.runtimeType}, value: ${cartNotifier.total}');

    final couponState = ref.watch(appliedCouponProvider);
    print('[Checkout] discount type: ${couponState.discount.runtimeType}, value: ${couponState.discount}');
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
    try {
      print('[Checkout] _buildPriceRow: label=$label, amount=$amount, amountType=${amount.runtimeType}');
      final intValue = amount.toInt();
      print('[Checkout] _buildPriceRow: converted to int=$intValue');

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
            '¥$intValue',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black,
            ),
          ),
        ],
      );
    } catch (e, stack) {
      print('[Checkout] ❌ ERROR in _buildPriceRow: $e');
      print('[Checkout] Stack: $stack');
      return Row(
        children: [
          Text('エラー: $label'),
          Text('$e'),
        ],
      );
    }
  }
}
