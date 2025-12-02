import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/models/menu_item_model.dart';
import '../providers/restaurant_menu_provider.dart';
import '../data/services/image_upload_service.dart';

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

  String _selectedCategory = 'メイン';
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _initialized = false;
  final List<XFile> _selectedImages = [];
  String? _existingImageUrl;
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

  void _removeExistingImage() {
    setState(() {
      _existingImageUrl = null;
    });
  }

  void _initializeForm(MenuItemModel menuItem) {
    if (!_initialized) {
      _nameController.text = menuItem.name;
      _descriptionController.text = menuItem.description ?? '';
      _priceController.text = menuItem.price.toStringAsFixed(0);
      _existingImageUrl = menuItem.imageUrl;

      // カテゴリがリストに存在しない場合は追加
      if (!_categories.contains(menuItem.category)) {
        _categories.add(menuItem.category);
      }
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        // Existing image
        if (_existingImageUrl != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _existingImageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: _removeExistingImage,
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
          const SizedBox(height: 12),
        ],

        // Add/Change image button
        if (_selectedImages.length < 10)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(_selectedImages.isEmpty && _existingImageUrl == null
              ? '画像を選択'
              : '画像を追加（${_selectedImages.length}/10）'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.grey[400]!),
            ),
          ),

        // New images preview
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

    // Upload new images if any selected
    String? imageUrl = _existingImageUrl;
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

    final success = await ref.read(updateMenuItemProvider.notifier).updateMenuItem(
      id: widget.menuItemId,
      name: _nameController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
      price: double.parse(_priceController.text),
      category: _selectedCategory,
      imageUrl: imageUrl,
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
      final (success, errorMessage) = await ref
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
            SnackBar(
              content: Text(errorMessage ?? '削除に失敗しました'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
