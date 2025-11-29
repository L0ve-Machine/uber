import '../../../../core/network/api_result.dart';
import '../../../../shared/models/user_model.dart';
import '../services/profile_api_service.dart';

/// Profile Repository
class ProfileRepository {
  final ProfileApiService _apiService;

  ProfileRepository({required ProfileApiService apiService})
      : _apiService = apiService;

  /// Get customer profile
  Future<ApiResult<UserModel>> getProfile() async {
    return await _apiService.getProfile();
  }

  /// Update customer profile
  Future<ApiResult<UserModel>> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    return await _apiService.updateProfile(
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }

  /// Change customer password
  Future<ApiResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _apiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
