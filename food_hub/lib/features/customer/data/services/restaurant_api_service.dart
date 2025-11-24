import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/restaurant_model.dart';
import '../../../../shared/models/menu_item_model.dart';

/// Restaurant API Service
class RestaurantApiService {
  final Dio _dio;

  RestaurantApiService(this._dio);

  /// Get all restaurants with optional filters
  Future<ApiResult<List<RestaurantModel>>> getRestaurants({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (latitude != null) queryParams['lat'] = latitude;
      if (longitude != null) queryParams['lng'] = longitude;
      if (radius != null) queryParams['radius'] = radius;

      final response = await _dio.get(
        '/restaurants',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final restaurantsList = data['restaurants'] as List<dynamic>;

        final restaurants = restaurantsList
            .map((json) => RestaurantModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(restaurants);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get restaurant by ID
  Future<ApiResult<RestaurantModel>> getRestaurantById(int id) async {
    try {
      final response = await _dio.get('/restaurants/$id');

      if (response.statusCode == 200) {
        final restaurant = RestaurantModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(restaurant);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get restaurant menu
  Future<ApiResult<List<MenuItemModel>>> getRestaurantMenu({
    required int restaurantId,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _dio.get(
        '/restaurants/$restaurantId/menu',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final menuItemsList = data['menu_items'] as List<dynamic>;

        final menuItems = menuItemsList
            .map((json) => MenuItemModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(menuItems);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get menu item by ID
  Future<ApiResult<MenuItemModel>> getMenuItemById(int id) async {
    try {
      final response = await _dio.get('/menu-items/$id');

      if (response.statusCode == 200) {
        final menuItem = MenuItemModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(menuItem);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
