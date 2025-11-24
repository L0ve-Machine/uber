import '../../../../core/network/api_result.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../shared/models/auth_models.dart';
import '../../../../shared/models/user_model.dart';
import '../services/auth_api_service.dart';

/// Auth Repository
/// Handles authentication business logic
class AuthRepository {
  final AuthApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required AuthApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  /// Login
  Future<ApiResult<UserModel>> login({
    required String email,
    required String password,
    required String userType,
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      userType: userType,
    );

    final result = await _apiService.login(request);

    return result.when(
      success: (loginResponse) async {
        // Save token and user data
        await _storageService.saveAuthToken(loginResponse.token);
        await _storageService.saveUser(loginResponse.user);

        return Success(loginResponse.user);
      },
      failure: (error) => Failure(error),
    );
  }

  /// Register customer
  Future<ApiResult<UserModel>> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final request = RegisterCustomerRequest(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    final result = await _apiService.registerCustomer(request);

    return result.when(
      success: (registerResponse) async {
        // Save token and user data
        await _storageService.saveAuthToken(registerResponse.token);
        await _storageService.saveUser(registerResponse.user);

        return Success(registerResponse.user);
      },
      failure: (error) => Failure(error),
    );
  }

  /// Get current user from storage
  Future<UserModel?> getCurrentUserFromStorage() async {
    return await _storageService.getUser();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Logout
  Future<void> logout() async {
    await _storageService.clearAuthData();
  }

  /// Refresh user data from API
  Future<ApiResult<UserModel>> refreshUserData() async {
    final result = await _apiService.getCurrentUser();

    return result.when(
      success: (data) async {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storageService.saveUser(user);
        return Success(user);
      },
      failure: (error) => Failure(error),
    );
  }
}
