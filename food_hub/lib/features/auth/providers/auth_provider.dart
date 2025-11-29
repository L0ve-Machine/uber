import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_api_service.dart';

part 'auth_provider.g.dart';

/// AuthApiService provider
@riverpod
AuthApiService authApiService(AuthApiServiceRef ref) {
  return AuthApiService(ref.watch(dioProvider));
}

/// AuthRepository provider
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    apiService: ref.watch(authApiServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
}

/// Auth state provider
/// Manages current user authentication state
@riverpod
class Auth extends _$Auth {
  @override
  Future<UserModel?> build() async {
    // Load user from storage on app start
    final repository = ref.watch(authRepositoryProvider);
    return await repository.getCurrentUserFromStorage();
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
    String userType = AppConstants.userTypeCustomer,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(
      email: email,
      password: password,
      userType: userType,
    );

    state = await AsyncValue.guard(() async {
      return result.when(
        success: (user) => user,
        failure: (error) => throw error,
      );
    });
  }

  /// Register customer
  Future<void> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.registerCustomer(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    state = await AsyncValue.guard(() async {
      return result.when(
        success: (user) => user,
        failure: (error) => throw error,
      );
    });
  }

  /// Logout
  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(null);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.refreshUserData();

    result.when(
      success: (user) {
        state = AsyncValue.data(user);
      },
      failure: (error) {
        // Keep current state on refresh error
        print('Failed to refresh user: $error');
      },
    );
  }

  /// Update user data (called from profile update)
  Future<void> updateUser(UserModel user) async {
    state = AsyncValue.data(user);
    // Also update storage
    final repository = ref.read(authRepositoryProvider);
    await repository.updateUserInStorage(user);
  }
}

/// Check if user is authenticated
@riverpod
Future<bool> isAuthenticated(IsAuthenticatedRef ref) async {
  final user = await ref.watch(authProvider.future);
  return user != null;
}
