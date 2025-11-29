import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_api_service.dart';

part 'profile_provider.g.dart';

/// ProfileApiService provider
@riverpod
ProfileApiService profileApiService(ProfileApiServiceRef ref) {
  return ProfileApiService(ref.watch(dioProvider));
}

/// ProfileRepository provider
@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(
    apiService: ref.watch(profileApiServiceProvider),
  );
}

/// Profile provider
@riverpod
class Profile extends _$Profile {
  @override
  Future<UserModel> build() async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.getProfile();

    return result.when(
      success: (user) => user,
      failure: (error) => throw error,
    );
  }

  /// Refresh profile
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.updateProfile(
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );

    result.when(
      success: (user) {
        state = AsyncValue.data(user);
        // Also update auth provider's user
        ref.read(authProvider.notifier).updateUser(user);
      },
      failure: (error) {
        throw error;
      },
    );
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    result.when(
      success: (_) {
        // Password changed successfully
      },
      failure: (error) {
        throw error;
      },
    );
  }
}
