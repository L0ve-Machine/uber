import '../../../../core/network/api_result.dart';
import '../../../../shared/models/menu_item_model.dart';
import '../../../../shared/models/restaurant_model.dart';
import '../services/restaurant_menu_api_service.dart';

/// Restaurant Menu Repository
class RestaurantMenuRepository {
  final RestaurantMenuApiService _apiService;

  RestaurantMenuRepository({required RestaurantMenuApiService apiService})
      : _apiService = apiService;

  /// Get restaurant's menu
  Future<ApiResult<List<MenuItemModel>>> getMenu({String? category}) async {
    return await _apiService.getMenu(category: category);
  }

  /// Add menu item
  Future<ApiResult<MenuItemModel>> addMenuItem({
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    List<Map<String, dynamic>>? options,
  }) async {
    return await _apiService.addMenuItem(
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      options: options,
    );
  }

  /// Update menu item
  Future<ApiResult<MenuItemModel>> updateMenuItem({
    required int id,
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    return await _apiService.updateMenuItem(
      id: id,
      name: name,
      description: description,
      price: price,
      category: category,
      imageUrl: imageUrl,
      isAvailable: isAvailable,
    );
  }

  /// Delete menu item
  Future<ApiResult<void>> deleteMenuItem(int id) async {
    return await _apiService.deleteMenuItem(id);
  }

  /// Toggle menu item availability
  Future<ApiResult<MenuItemModel>> toggleAvailability(int id) async {
    return await _apiService.toggleAvailability(id);
  }

  /// Get restaurant profile (with Stripe status)
  Future<ApiResult<RestaurantModel>> getProfile() async {
    return await _apiService.getProfile();
  }
}
