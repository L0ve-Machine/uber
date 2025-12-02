import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/custom_button.dart';
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
  XFile? _selectedLogoImage;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickLogoImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedLogoImage = image;
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedCoverImage == null && _selectedLogoImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画像を選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadService = ImageUploadService(ref.read(dioProvider));
      final imagesToUpload = <XFile>[];

      if (_selectedCoverImage != null) imagesToUpload.add(_selectedCoverImage!);
      if (_selectedLogoImage != null) imagesToUpload.add(_selectedLogoImage!);

      final result = await uploadService.uploadRestaurantImages(imagesToUpload);

      await result.when(
        success: (urls) async {
          // Update restaurant profile with new image URLs
          // For now, just show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('画像をアップロードしました'),
                backgroundColor: Colors.green,
              ),
            );

            // Refresh profile
            ref.invalidate(restaurantProfileProvider);

            // Go back
            Navigator.of(context).pop();
          }
        },
        failure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('アップロードに失敗しました: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
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
        title: const Text('お店の写真設定'),
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

            // Logo Image Section
            const Text(
              'ロゴ画像 (任意)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '店舗のロゴやアイコン',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickLogoImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedLogoImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedLogoImage!.path),
                          fit: BoxFit.contain,
                        ),
                      )
                    : profileAsync.when(
                        data: (profile) {
                          if (profile.logoUrl != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: profile.logoUrl!,
                                fit: BoxFit.contain,
                              ),
                            );
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 32, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'タップして画像を選択',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
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
                                size: 32, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'タップして画像を選択',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            CustomButton(
              text: 'アップロード',
              onPressed: _isUploading ? null : _uploadImages,
              isLoading: _isUploading,
            ),
          ],
        ),
      ),
    );
  }
}
