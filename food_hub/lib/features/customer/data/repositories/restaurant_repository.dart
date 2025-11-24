import '../../../../core/network/api_result.dart';
import '../../../../shared/models/restaurant_model.dart';
import '../../../../shared/models/menu_item_model.dart';
import '../services/restaurant_api_service.dart';

/// Restaurant Repository
class RestaurantRepository {
  final RestaurantApiService _apiService;

  RestaurantRepository({required RestaurantApiService apiService})
      : _apiService = apiService;

  /// Get all restaurants
  Future<ApiResult<List<RestaurantModel>>> getRestaurants({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    return await _apiService.getRestaurants(
      category: category,
      search: search,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Get restaurant by ID
  Future<ApiResult<RestaurantModel>> getRestaurantById(int id) async {
    return await _apiService.getRestaurantById(id);
  }

  /// Get restaurant menu
  Future<ApiResult<List<MenuItemModel>>> getRestaurantMenu({
    required int restaurantId,
    String? category,
  }) async {
    return await _apiService.getRestaurantMenu(
      restaurantId: restaurantId,
      category: category,
    );
  }

  /// Get menu item by ID
  Future<ApiResult<MenuItemModel>> getMenuItemById(int id) async {
    return await _apiService.getMenuItemById(id);
  }
}
