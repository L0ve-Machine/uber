import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/menu_item_model.dart';
import '../data/repositories/restaurant_menu_repository.dart';
import '../data/services/restaurant_menu_api_service.dart';
import 'restaurant_profile_provider.dart';

part 'restaurant_menu_provider.g.dart';

/// RestaurantMenuApiService provider
@riverpod
RestaurantMenuApiService restaurantMenuApiService(RestaurantMenuApiServiceRef ref) {
  return RestaurantMenuApiService(ref.watch(dioProvider));
}

/// RestaurantMenuRepository provider
@riverpod
RestaurantMenuRepository restaurantMenuRepository(RestaurantMenuRepositoryRef ref) {
  return RestaurantMenuRepository(
    apiService: ref.watch(restaurantMenuApiServiceProvider),
  );
}

/// Restaurant menu list provider
@riverpod
class RestaurantMenu extends _$RestaurantMenu {
  String? _currentCategory;

  @override
  Future<List<MenuItemModel>> build({String? category}) async {
    _currentCategory = category;

    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.getMenu(category: category);

    return result.when(
      success: (menuItems) => menuItems,
      failure: (error) => throw error,
    );
  }

  /// Refresh menu
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(category: _currentCategory));
  }

  /// Filter by category
  Future<void> filterByCategory(String? category) async {
    _currentCategory = category;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(category: category));
  }

  /// Toggle availability
  Future<bool> toggleAvailability(int menuItemId) async {
    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.toggleAvailability(menuItemId);

    return result.when(
      success: (updatedItem) {
        // Update the item in the list
        state.whenData((items) {
          final updatedItems = items.map((item) {
            return item.id == updatedItem.id ? updatedItem : item;
          }).toList();
          state = AsyncValue.data(updatedItems);
        });
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Delete menu item
  /// Returns (success, errorMessage)
  Future<(bool, String?)> deleteMenuItem(int menuItemId) async {
    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.deleteMenuItem(menuItemId);

    return result.when(
      success: (_) {
        // Remove the item from the list
        state.whenData((items) {
          final updatedItems = items.where((item) => item.id != menuItemId).toList();
          state = AsyncValue.data(updatedItems);
        });
        return (true, null);
      },
      failure: (error) => (false, error.message),
    );
  }
}

/// Add menu item action provider
@riverpod
class AddMenuItem extends _$AddMenuItem {
  @override
  FutureOr<MenuItemModel?> build() {
    return null;
  }

  /// Add new menu item
  /// Returns (success, errorMessage)
  Future<(bool, String?)> add({
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    List<Map<String, dynamic>>? options,
  }) async {
    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.addMenuItem(
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      options: options,
    );

    return result.when(
      success: (menuItem) {
        // Invalidate menu list to refresh
        ref.invalidate(restaurantMenuProvider());
        return (true, null);
      },
      failure: (error) {
        return (false, error.message);
      },
    );
  }
}

/// Update menu item action provider
@riverpod
class UpdateMenuItem extends _$UpdateMenuItem {
  @override
  FutureOr<MenuItemModel?> build() {
    return null;
  }

  /// Update existing menu item
  Future<bool> updateMenuItem({
    required int id,
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    final repository = ref.read(restaurantMenuRepositoryProvider);
    final result = await repository.updateMenuItem(
      id: id,
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );

    final success = result.when(
      success: (menuItem) {
        // Invalidate menu list to refresh
        ref.invalidate(restaurantMenuProvider());
        return true;
      },
      failure: (error) {
        return false;
      },
    );

    return success;
  }
}
