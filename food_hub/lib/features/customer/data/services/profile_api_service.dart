import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/user_model.dart';

/// Profile API Service
class ProfileApiService {
  final Dio _dio;

  ProfileApiService(this._dio);

  /// Get customer profile
  Future<ApiResult<UserModel>> getProfile() async {
    try {
      final response = await _dio.get('/customers/profile');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return Success(user);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Update customer profile
  Future<ApiResult<UserModel>> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;

      final response = await _dio.put('/customers/profile', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final user = UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
        return Success(user);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Change customer password
  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/customers/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
