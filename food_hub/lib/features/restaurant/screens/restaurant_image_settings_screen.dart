import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../data/services/image_upload_service.dart';
import '../providers/restaurant_profile_provider.dart';

class RestaurantImageSettingsScreen extends ConsumerStatefulWidget {
  const RestaurantImageSettingsScreen({super.key});

  @override
  ConsumerState<RestaurantImageSettingsScreen> createState() =>
      _RestaurantImageSettingsScreenState();
}

class _RestaurantImageSettingsScreenState
    extends ConsumerState<RestaurantImageSettingsScreen> {
  XFile? _selectedCoverImage;
  bool _isUploading = false;
  final _deliveryTimeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedCoverImage = image;
      });
    }
  }

  Future<void> _uploadImages() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final deliveryTime = int.tryParse(_deliveryTimeController.text.trim());

      String? coverImageUrl;

      // Upload image if selected
      if (_selectedCoverImage != null) {
        final uploadService = ImageUploadService(dio);
        final result = await uploadService.uploadRestaurantImages([_selectedCoverImage!]);

        final uploadSuccess = await result.when(
          success: (urls) {
            if (urls.isNotEmpty) {
              coverImageUrl = urls.first;
            }
            return true;
          },
          failure: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('画像アップロードに失敗しました: ${error.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          },
        );

        if (!uploadSuccess) {
          return;
        }
      }

      // Update profile (image URL and/or delivery time)
      await dio.patch('/restaurant/profile', data: {
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (deliveryTime != null) 'delivery_time_minutes': deliveryTime,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('設定を保存しました'),
            backgroundColor: Colors.green,
          ),
        );

        ref.invalidate(restaurantProfileProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(restaurantProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('店舗設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image Section
            const Text(
              'カバー画像',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '顧客のホーム画面で表示されるメイン画像',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedCoverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedCoverImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : profileAsync.when(
                        data: (profile) {
                          if (profile.coverImageUrl != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: profile.coverImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            );
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'タップして画像を選択',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (_, __) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'タップして画像を選択',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Delivery Time Section
            const Text(
              '配達時間',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '通常の配達にかかる時間（分）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            CustomTextField(
              controller: _deliveryTimeController,
              label: '配達時間（分）',
              keyboardType: TextInputType.number,
              hintText: '例: 30',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '配達時間を入力してください';
                }
                final minutes = int.tryParse(value);
                if (minutes == null || minutes < 10 || minutes > 120) {
                  return '10〜120分の範囲で入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: '保存',
              onPressed: _isUploading ? null : _uploadImages,
              isLoading: _isUploading,
            ),
          ],
        ),
      ),
    );
  }
}
