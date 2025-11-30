import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);

    // デバッグログ
    print('[Cart] build() called');
    print('[Cart] Cart items count: ${cartItems.length}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('カート'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
              child: const Text(
                'すべて削除',
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'カートは空です',
              message: 'お好きな料理を追加してください',
              action: CustomButton(
                text: 'レストランを探す',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                width: 200,
              ),
            )
          : Column(
              children: [
                // Warning if multiple restaurants
                if (!cartNotifier.isFromSingleRestaurant)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange[100],
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '複数のレストランの商品が含まれています。1つのレストランのみから注文できます。',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemTile(
                        cartItem: item,
                        onIncrement: () {
                          ref.read(cartProvider.notifier).incrementQuantity(item.id);
                        },
                        onDecrement: () {
                          ref.read(cartProvider.notifier).decrementQuantity(item.id);
                        },
                        onRemove: () {
                          ref.read(cartProvider.notifier).removeItem(item.id);
                        },
                      );
                    },
                  ),
                ),

                // Price Summary
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPriceRow('小計', cartNotifier.subtotal),
                          const SizedBox(height: 8),
                          _buildPriceRow('配送料', cartNotifier.deliveryFee),
                          const SizedBox(height: 8),
                          _buildPriceRow('消費税', cartNotifier.tax),
                          const Divider(height: 24),
                          _buildPriceRow(
                            '合計',
                            cartNotifier.total,
                            isTotal: true,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'チェックアウトへ進む',
                            onPressed: cartNotifier.isFromSingleRestaurant
                                ? () {
                                    print('[Cart] Navigating to checkout');
                                    print('[Cart] Cart items count before navigation: ${cartItems.length}');
                                    print('[Cart] Cart items: ${cartItems.map((item) => item.menuItem.name).toList()}');
                                    Navigator.of(context).pushNamed('/customer/checkout');
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '¥${amount.toInt()}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.black : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カートをクリア'),
        content: const Text('カート内のすべての商品を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.of(context).pop();
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final cartItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.cartItem,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cartItem.menuItem.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: cartItem.menuItem.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, size: 24),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 24),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Selected options
                  if (cartItem.selectedOptions.isNotEmpty) ...[
                    ...cartItem.selectedOptions.map((option) => Text(
                          '+ ${option.name} (¥${option.price.toInt()})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )),
                    const SizedBox(height: 4),
                  ],

                  // Special request
                  if (cartItem.specialRequest != null &&
                      cartItem.specialRequest!.isNotEmpty) ...[
                    Text(
                      'リクエスト: ${cartItem.specialRequest}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 8),

                  // Price and quantity controls
                  Row(
                    children: [
                      Text(
                        '¥${cartItem.unitPrice.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),

                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                cartItem.quantity == 1
                                    ? Icons.delete_outline
                                    : Icons.remove,
                                size: 20,
                              ),
                              onPressed: onDecrement,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: onIncrement,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
