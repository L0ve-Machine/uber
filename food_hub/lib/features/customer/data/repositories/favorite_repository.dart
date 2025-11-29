import '../../../../core/network/api_result.dart';
import '../../../../shared/models/favorite_model.dart';
import '../services/favorite_api_service.dart';

/// Favorite Repository
class FavoriteRepository {
  final FavoriteApiService _apiService;

  FavoriteRepository({required FavoriteApiService apiService})
      : _apiService = apiService;

  /// Get customer's favorites
  Future<ApiResult<List<FavoriteModel>>> getFavorites() async {
    return await _apiService.getFavorites();
  }

  /// Add restaurant to favorites
  Future<ApiResult<FavoriteModel>> addFavorite(int restaurantId) async {
    return await _apiService.addFavorite(restaurantId);
  }

  /// Remove restaurant from favorites
  Future<ApiResult<void>> removeFavorite(int favoriteId) async {
    return await _apiService.removeFavorite(favoriteId);
  }
}
