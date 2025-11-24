import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/models/menu_item_model.dart';
import '../data/repositories/restaurant_repository.dart';
import '../data/services/restaurant_api_service.dart';

part 'restaurant_provider.g.dart';

/// RestaurantApiService provider
@riverpod
RestaurantApiService restaurantApiService(RestaurantApiServiceRef ref) {
  return RestaurantApiService(ref.watch(dioProvider));
}

/// RestaurantRepository provider
@riverpod
RestaurantRepository restaurantRepository(RestaurantRepositoryRef ref) {
  return RestaurantRepository(
    apiService: ref.watch(restaurantApiServiceProvider),
  );
}

/// Restaurant list provider with optional filters
@riverpod
class RestaurantList extends _$RestaurantList {
  String? _currentCategory;
  String? _currentSearch;

  @override
  Future<List<RestaurantModel>> build({
    String? category,
    String? search,
  }) async {
    _currentCategory = category;
    _currentSearch = search;

    final repository = ref.read(restaurantRepositoryProvider);
    final result = await repository.getRestaurants(
      category: category,
      search: search,
    );

    return result.when(
      success: (restaurants) => restaurants,
      failure: (error) => throw error,
    );
  }

  /// Refresh restaurant list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(
          category: _currentCategory,
          search: _currentSearch,
        ));
  }

  /// Update filters
  Future<void> updateFilters({String? category, String? search}) async {
    _currentCategory = category;
    _currentSearch = search;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(
          category: category,
          search: search,
        ));
  }
}

/// Restaurant detail provider by ID
@riverpod
class RestaurantDetail extends _$RestaurantDetail {
  @override
  Future<RestaurantModel> build(int restaurantId) async {
    final repository = ref.read(restaurantRepositoryProvider);
    final result = await repository.getRestaurantById(restaurantId);

    return result.when(
      success: (restaurant) => restaurant,
      failure: (error) => throw error,
    );
  }

  /// Refresh restaurant details
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(restaurantId));
  }
}

/// Restaurant menu provider
@riverpod
class RestaurantMenu extends _$RestaurantMenu {
  String? _currentCategory;

  @override
  Future<List<MenuItemModel>> build({
    required int restaurantId,
    String? category,
  }) async {
    _currentCategory = category;

    final repository = ref.read(restaurantRepositoryProvider);
    final result = await repository.getRestaurantMenu(
      restaurantId: restaurantId,
      category: category,
    );

    return result.when(
      success: (menuItems) => menuItems,
      failure: (error) => throw error,
    );
  }

  /// Refresh menu
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(
          restaurantId: restaurantId,
          category: _currentCategory,
        ));
  }

  /// Filter by category
  Future<void> filterByCategory(String? category) async {
    _currentCategory = category;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(
          restaurantId: restaurantId,
          category: category,
        ));
  }
}

/// Get unique menu categories from menu items
@riverpod
List<String> menuCategories(MenuCategoriesRef ref, int restaurantId) {
  final menuAsync = ref.watch(restaurantMenuProvider(restaurantId: restaurantId));

  return menuAsync.when(
    data: (menuItems) {
      final categories = menuItems.map((item) => item.category).toSet().toList();
      categories.sort();
      return categories;
    },
    loading: () => [],
    error: (_, __) => [],
  );
}
