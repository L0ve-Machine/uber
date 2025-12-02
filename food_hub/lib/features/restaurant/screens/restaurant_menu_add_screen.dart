import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/restaurant_menu_provider.dart';
import '../data/services/image_upload_service.dart';
import 'restaurant_stripe_setup_screen.dart';

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

  String _selectedCategory = 'メイン';
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['メイン', 'サイド', 'ドリンク', 'デザート', 'その他'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(10 - _selectedImages.length));
        });
      }
    } catch (e) {
      print('画像選択エラー: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('メニュー追加'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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

              // Image picker
              const Text(
                '商品画像',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildImagePicker(),
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        // Add image button
        if (_selectedImages.length < 10)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(_selectedImages.isEmpty ? '画像を選択' : '画像を追加（${_selectedImages.length}/10）'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.grey[400]!),
            ),
          ),

        // Selected images preview
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Upload images first if any selected
    String? imageUrl;
    if (_selectedImages.isNotEmpty) {
      final uploadService = ImageUploadService(ref.read(dioProvider));
      final result = await uploadService.uploadMenuImages(_selectedImages);

      final uploadSuccess = result.when(
        success: (urls) {
          if (urls.isNotEmpty) {
            imageUrl = urls[0]; // Use first image as primary
          }
          return true;
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('画像アップロードに失敗しました: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        },
      );

      if (!uploadSuccess) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    final (success, errorMessage) = await ref.read(addMenuItemProvider.notifier).add(
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      imageUrl: imageUrl,
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
        // エラーハンドリング拡張
        final isStripeError = errorMessage?.contains('Stripe') ?? false;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isStripeError ? 'Stripe設定が必要です' : 'エラー'),
            content: Text(
              isStripeError
                  ? (errorMessage ?? 'Stripe設定が必要です') +
                      '\n\n設定画面からStripe登録を完了してください。'
                  : (errorMessage ?? 'メニューの追加に失敗しました'),
            ),
            actions: [
              if (isStripeError)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RestaurantStripeSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('設定画面へ'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isStripeError ? 'キャンセル' : '閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }
}
