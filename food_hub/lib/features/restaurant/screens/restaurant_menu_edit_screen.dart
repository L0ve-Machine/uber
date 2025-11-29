import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/models/menu_item_model.dart';
import '../providers/restaurant_menu_provider.dart';

class RestaurantMenuEditScreen extends ConsumerStatefulWidget {
  final int menuItemId;

  const RestaurantMenuEditScreen({
    super.key,
    required this.menuItemId,
  });

  @override
  ConsumerState<RestaurantMenuEditScreen> createState() => _RestaurantMenuEditScreenState();
}

class _RestaurantMenuEditScreenState extends ConsumerState<RestaurantMenuEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Main';
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _initialized = false;

  final List<String> _categories = ['Main', 'Side', 'Drink', 'Dessert', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _initializeForm(MenuItemModel menuItem) {
    if (!_initialized) {
      _nameController.text = menuItem.name;
      _descriptionController.text = menuItem.description ?? '';
      _priceController.text = menuItem.price.toStringAsFixed(0);
      _imageUrlController.text = menuItem.imageUrl ?? '';
      _selectedCategory = menuItem.category;
      _isAvailable = menuItem.isAvailable;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(restaurantMenuProvider());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('メニュー編集'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _handleDelete(),
          ),
        ],
      ),
      body: menuAsync.when(
        data: (menuItems) {
          final menuItem = menuItems.where((item) => item.id == widget.menuItemId).firstOrNull;

          if (menuItem == null) {
            return const Center(child: Text('メニューが見つかりません'));
          }

          _initializeForm(menuItem);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('提供可能'),
                      subtitle: Text(
                        _isAvailable ? '現在提供中' : '現在提供停止中',
                        style: TextStyle(
                          color: _isAvailable ? AppColors.success : Colors.red,
                        ),
                      ),
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                      activeColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  CustomTextField(
                    controller: _nameController,
                    labelText: '商品名 *',
                    hintText: '例: ハンバーガー',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '商品名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: '説明',
                    hintText: '商品の説明を入力...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Price
                  CustomTextField(
                    controller: _priceController,
                    labelText: '価格 *',
                    hintText: '例: 1200',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.currency_yen),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '価格を入力してください';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price < 0) {
                        return '有効な価格を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  const Text(
                    'カテゴリ *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image URL
                  CustomTextField(
                    controller: _imageUrlController,
                    labelText: '画像URL',
                    hintText: 'https://example.com/image.jpg',
                    keyboardType: TextInputType.url,
                    prefixIcon: const Icon(Icons.image),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '変更を保存',
                      isLoading: _isLoading,
                      onPressed: _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'メニューを読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(restaurantMenuProvider());
          },
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(updateMenuItemProvider.notifier).updateMenuItem(
      id: widget.menuItemId,
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : null,
      isAvailable: _isAvailable,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('メニューを更新しました'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューの更新に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メニューを削除'),
        content: const Text('このメニューを削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(restaurantMenuProvider().notifier)
          .deleteMenuItem(widget.menuItemId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メニューを削除しました'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('削除に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
