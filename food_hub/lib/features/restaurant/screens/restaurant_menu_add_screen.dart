import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/restaurant_menu_provider.dart';

class RestaurantMenuAddScreen extends ConsumerStatefulWidget {
  const RestaurantMenuAddScreen({super.key});

  @override
  ConsumerState<RestaurantMenuAddScreen> createState() => _RestaurantMenuAddScreenState();
}

class _RestaurantMenuAddScreenState extends ConsumerState<RestaurantMenuAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Main';
  bool _isLoading = false;

  final List<String> _categories = ['Main', 'Side', 'Drink', 'Dessert', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('メニュー追加'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  text: 'メニューを追加',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await ref.read(addMenuItemProvider.notifier).add(
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('メニューを追加しました'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メニューの追加に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
