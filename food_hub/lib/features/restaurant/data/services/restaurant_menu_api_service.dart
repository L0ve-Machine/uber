import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/menu_item_model.dart';

/// Restaurant Menu API Service
class RestaurantMenuApiService {
  final Dio _dio;

  RestaurantMenuApiService(this._dio);

  /// Get restaurant's own menu
  Future<ApiResult<List<MenuItemModel>>> getMenu({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;

      final response = await _dio.get(
        '/restaurant/menu',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final menuList = data['menu_items'] as List<dynamic>;

        final menuItems = menuList
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

  /// Add menu item
  Future<ApiResult<MenuItemModel>> addMenuItem({
    required String name,
    String? description,
    required double price,
    required String category,
    String? imageUrl,
    List<Map<String, dynamic>>? options,
  }) async {
    try {
      final response = await _dio.post(
        '/restaurant/menu',
        data: {
          'name': name,
          if (description != null) 'description': description,
          'price': price,
          'category': category,
          if (imageUrl != null) 'image_url': imageUrl,
          if (options != null) 'options': options,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final menuItem = MenuItemModel.fromJson(
          data['menu_item'] as Map<String, dynamic>,
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
    try {
      final response = await _dio.put(
        '/restaurant/menu/$id',
        data: {
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'image_url': imageUrl,
          if (isAvailable != null) 'is_available': isAvailable,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final menuItem = MenuItemModel.fromJson(
          data['menu_item'] as Map<String, dynamic>,
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

  /// Delete menu item
  Future<ApiResult<void>> deleteMenuItem(int id) async {
    try {
      final response = await _dio.delete('/restaurant/menu/$id');

      if (response.statusCode == 200) {
        return Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Toggle menu item availability
  Future<ApiResult<MenuItemModel>> toggleAvailability(int id) async {
    try {
      final response = await _dio.patch('/restaurant/menu/$id/availability');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final menuItem = MenuItemModel.fromJson(
          data['menu_item'] as Map<String, dynamic>,
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
