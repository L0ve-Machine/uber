import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/driver_model.dart';
import 'driver_provider.dart';

part 'driver_profile_provider.g.dart';

@riverpod
class DriverProfile extends _$DriverProfile {
  @override
  Future<DriverModel> build() async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.getProfile();

    return result.when(
      success: (driver) => driver,
      failure: (error) => throw error,
    );
  }

  /// プロフィールをリフレッシュ（Stripe設定後に呼ぶ）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
