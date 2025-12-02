import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';

/// 画像アップロードサービス
class ImageUploadService {
  final Dio _dio;

  ImageUploadService(this._dio);

  /// メニュー画像をアップロード（複数可）
  Future<ApiResult<List<String>>> uploadMenuImages(List<XFile> images) async {
    try {
      final formData = FormData();

      for (var image in images) {
        final bytes = await image.readAsBytes();
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              bytes,
              filename: image.name,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/upload/menu-images',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final urls = (data['image_urls'] as List<dynamic>)
            .map((url) => url as String)
            .toList();
        return Success(urls);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// レストラン画像をアップロード（複数可）
  Future<ApiResult<List<String>>> uploadRestaurantImages(List<XFile> images) async {
    try {
      final formData = FormData();

      for (var image in images) {
        final bytes = await image.readAsBytes();
        formData.files.add(
          MapEntry(
            'images',
            MultipartFile.fromBytes(
              bytes,
              filename: image.name,
            ),
          ),
        );
      }

      final response = await _dio.post(
        '/upload/restaurant-images',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final urls = (data['image_urls'] as List<dynamic>)
            .map((url) => url as String)
            .toList();
        return Success(urls);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// 画像を削除
  Future<ApiResult<void>> deleteImage(String imageUrl) async {
    try {
      final response = await _dio.delete(
        '/upload/image',
        data: {'image_url': imageUrl},
      );

      if (response.statusCode == 200) {
        return Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
