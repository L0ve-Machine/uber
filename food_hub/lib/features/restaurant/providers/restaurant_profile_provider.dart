import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/restaurant_model.dart';
import 'restaurant_menu_provider.dart';

part 'restaurant_profile_provider.g.dart';

@riverpod
class RestaurantProfile extends _$RestaurantProfile {
  @override
  Future<RestaurantModel> build() async {
    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.getProfile();

    return result.when(
      success: (restaurant) => restaurant,
      failure: (error) => throw error,
    );
  }

  /// プロフィールをリフレッシュ（Stripe設定後に呼ぶ）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// 住所を更新
  Future<bool> updateAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final repository = ref.read(restaurantMenuRepositoryProvider);
      final result = await repository.updateAddress(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

      return result.when(
        success: (restaurant) {
          // 状態を更新
          state = AsyncValue.data(restaurant);
          return true;
        },
        failure: (error) {
          print('[RestaurantProfile] Address update failed: $error');
          return false;
        },
      );
    } catch (e) {
      print('[RestaurantProfile] Address update error: $e');
      return false;
    }
  }
}
