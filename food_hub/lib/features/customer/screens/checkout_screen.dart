import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/address_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
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
  String _paymentMethod = 'cash';
  bool _isPlacingOrder = false;
  AddressModel? _selectedAddress;

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

      result.when(
        success: (order) async {
          // Check if payment method is card
          if (_paymentMethod == 'card') {
            // TODO: Implement Stripe payment flow
            // 1. Call create-payment-intent API
            // 2. Show Stripe payment sheet
            // 3. On success, navigate to confirmation

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('カード決済機能は準備中です。現金支払いをご利用ください。'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );

            // For now, navigate directly (cash-like behavior)
            Navigator.of(context).pushReplacementNamed(
              '/customer/order-confirmation',
              arguments: order,
            );
          } else {
            // Cash payment - navigate directly
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
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    final defaultAddressAsync = ref.watch(defaultAddressProvider);

    // Set initial address
    if (_selectedAddress == null) {
      defaultAddressAsync.whenData((address) {
        if (address != null && _selectedAddress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedAddress = address;
            });
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('チェックアウト'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('カートが空です'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  _buildSectionTitle('配達先住所'),
                  const SizedBox(height: 8),
                  _buildAddressCard(),

                  const SizedBox(height: 24),

                  // Order Items Section
                  _buildSectionTitle('注文内容'),
                  const SizedBox(height: 8),
                  _buildOrderItemsList(cartItems),

                  const SizedBox(height: 24),

                  // Coupon Section
                  _buildSectionTitle('クーポン'),
                  const SizedBox(height: 8),
                  _buildCouponSection(),

                  const SizedBox(height: 24),

                  // Special Instructions
                  _buildSectionTitle('特別リクエスト（オプション）'),
                  const SizedBox(height: 8),
                  TextField(
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

                  const SizedBox(height: 24),

                  // Payment Method
                  _buildSectionTitle('お支払い方法'),
                  const SizedBox(height: 8),
                  _buildPaymentMethodSelector(),

                  const SizedBox(height: 24),

                  // Price Summary
                  _buildSectionTitle('料金詳細'),
                  const SizedBox(height: 8),
                  _buildPriceSummary(cartNotifier, ref),

                  const SizedBox(height: 32),

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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAddressCard() {
    final addressAsync = ref.watch(defaultAddressProvider);

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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: addressAsync.when(
            loading: () => const LoadingIndicator(),
            error: (_, __) => const Text('住所の読み込みに失敗しました'),
            data: (defaultAddress) {
              final address = _selectedAddress ?? defaultAddress;

              if (address == null) {
                return Row(
                  children: [
                    Icon(Icons.add_location, color: Colors.black),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('配達先を追加'),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getLabelIcon(address.label),
                    color: Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLabelText(address.label),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.fullAddress,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '変更',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _getLabelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
      case '自宅':
        return Icons.home;
      case 'work':
      case 'office':
      case '会社':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }

  String _getLabelText(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return '自宅';
      case 'work':
      case 'office':
        return '会社';
      default:
        return label;
    }
  }

  Widget _buildOrderItemsList(List cartItems) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.menuItem.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.menuItem.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, size: 24),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 24),
                    ),
            ),
            title: Text(item.menuItem.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.selectedOptions.isNotEmpty)
                  Text(
                    item.selectedOptions.map((o) => o.name).join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text('x${item.quantity}'),
              ],
            ),
            trailing: Text(
              '¥${item.totalPrice.toInt()}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
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
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
            title: Row(
              children: [
                const Icon(Icons.credit_card),
                const SizedBox(width: 12),
                const Text('クレジットカード'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '準備中',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            activeColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(Cart cartNotifier, WidgetRef ref) {
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
              _buildPriceRow('クーポン割引', -discount, isDiscount: true),
            ],
            const Divider(height: 24),
            _buildPriceRow('合計', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    final couponState = ref.watch(appliedCouponProvider);

    if (couponState.coupon != null) {
      // Coupon applied - show applied coupon
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: Colors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      couponState.coupon!.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '-¥${couponState.discount}',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

    // No coupon - show input field
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'クーポンコードを入力',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: couponState.isLoading
                      ? null
                      : () async {
                          if (_couponController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('クーポンコードを入力してください'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final cartNotifier = ref.read(cartProvider.notifier);
                          final success = await ref
                              .read(appliedCouponProvider.notifier)
                              .applyCoupon(
                                code: _couponController.text.trim(),
                                subtotal: cartNotifier.subtotal,
                              );

                          if (!mounted) return;

                          if (success) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: couponState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('適用'),
                ),
              ],
            ),
            if (couponState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                couponState.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.black : (isTotal ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text(
          '¥${amount.toInt()}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isDiscount ? Colors.black : (isTotal ? Colors.black : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
