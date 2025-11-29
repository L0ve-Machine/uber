import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/favorite_model.dart';

/// Favorite API Service
class FavoriteApiService {
  final Dio _dio;

  FavoriteApiService(this._dio);

  /// Get customer's favorites
  Future<ApiResult<List<FavoriteModel>>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final favoritesList = data['favorites'] as List<dynamic>;

        final favorites = favoritesList
            .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(favorites);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Add restaurant to favorites
  Future<ApiResult<FavoriteModel>> addFavorite(int restaurantId) async {
    try {
      final response = await _dio.post(
        '/favorites',
        data: {'restaurant_id': restaurantId},
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final favorite = FavoriteModel.fromJson(
          data['favorite'] as Map<String, dynamic>,
        );
        return Success(favorite);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Remove restaurant from favorites
  Future<ApiResult<void>> removeFavorite(int favoriteId) async {
    try {
      final response = await _dio.delete('/favorites/$favoriteId');

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
