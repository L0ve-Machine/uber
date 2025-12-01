import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/order_model.dart';
import '../providers/cart_provider.dart';

class AddToCartSheet extends ConsumerStatefulWidget {
  final MenuItemModel menuItem;

  const AddToCartSheet({
    super.key,
    required this.menuItem,
  });

  @override
  ConsumerState<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends ConsumerState<AddToCartSheet> {
  int _quantity = 1;
  final Map<String, SelectedOptionModel> _selectedOptions = {};
  final _specialRequestController = TextEditingController();

  @override
  void dispose() {
    _specialRequestController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _toggleOption(MenuItemOptionModel option) {
    setState(() {
      final key = '${option.optionGroupName}_${option.optionName}';
      if (_selectedOptions.containsKey(key)) {
        _selectedOptions.remove(key);
      } else {
        _selectedOptions[key] = SelectedOptionModel(
          group: option.optionGroupName,
          name: option.optionName,
          price: option.additionalPrice,
        );
      }
    });
  }

  double _calculateTotal() {
    final basePrice = widget.menuItem.price * _quantity;
    final optionsPrice = _selectedOptions.values.fold<double>(
      0,
      (sum, option) => sum + (option.price * _quantity),
    );
    return basePrice + optionsPrice;
  }

  void _addToCart() {
    ref.read(cartProvider.notifier).addItem(
          menuItem: widget.menuItem,
          quantity: _quantity,
          selectedOptions: _selectedOptions.values.toList(),
          specialRequest: _specialRequestController.text.isEmpty
              ? null
              : _specialRequestController.text,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.menuItem.name} をカートに追加しました'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    // Group options by group name
    final optionGroups = <String, List<MenuItemOptionModel>>{};
    if (widget.menuItem.options != null) {
      for (final option in widget.menuItem.options!) {
        if (!optionGroups.containsKey(option.optionGroupName)) {
          optionGroups[option.optionGroupName] = [];
        }
        optionGroups[option.optionGroupName]!.add(option);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Item Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (widget.menuItem.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.menuItem.imageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),

                      // Name and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.menuItem.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.menuItem.description != null)
                              Text(
                                widget.menuItem.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '¥${widget.menuItem.price.toInt()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Options
                  if (optionGroups.isNotEmpty) ...[
                    ...optionGroups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map((option) {
                            final key = '${option.optionGroupName}_${option.optionName}';
                            final isSelected = _selectedOptions.containsKey(key);

                            return CheckboxListTile(
                              title: Text(option.optionName),
                              subtitle: option.additionalPrice > 0
                                  ? Text('+¥${option.additionalPrice.toInt()}')
                                  : null,
                              value: isSelected,
                              onChanged: (value) {
                                _toggleOption(option);
                              },
                              activeColor: Colors.black,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],

                  // Special request
                  const Text(
                    '特別なリクエスト',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _specialRequestController,
                    hintText: '例: アレルギー対応、辛さ調整など',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  Row(
                    children: [
                      const Text(
                        '数量',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1 ? _decrementQuantity : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _incrementQuantity,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Add to cart button
          Container(
            padding: const EdgeInsets.all(20),
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
              child: CustomButton(
                text: 'カートに追加 - ¥${total.toInt()}',
                onPressed: _addToCart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
