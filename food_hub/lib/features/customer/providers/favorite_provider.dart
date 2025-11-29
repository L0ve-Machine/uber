import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/favorite_model.dart';
import '../data/repositories/favorite_repository.dart';
import '../data/services/favorite_api_service.dart';

part 'favorite_provider.g.dart';

/// FavoriteApiService provider
@riverpod
FavoriteApiService favoriteApiService(FavoriteApiServiceRef ref) {
  return FavoriteApiService(ref.watch(dioProvider));
}

/// FavoriteRepository provider
@riverpod
FavoriteRepository favoriteRepository(FavoriteRepositoryRef ref) {
  return FavoriteRepository(
    apiService: ref.watch(favoriteApiServiceProvider),
  );
}

/// Favorite list provider
@riverpod
class FavoriteList extends _$FavoriteList {
  @override
  Future<List<FavoriteModel>> build() async {
    final repository = ref.read(favoriteRepositoryProvider);
    final result = await repository.getFavorites();

    return result.when(
      success: (favorites) => favorites,
      failure: (error) => throw error,
    );
  }

  /// Refresh favorites list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Add restaurant to favorites
  Future<void> addFavorite(int restaurantId) async {
    final repository = ref.read(favoriteRepositoryProvider);
    final result = await repository.addFavorite(restaurantId);

    result.when(
      success: (favorite) {
        // Add to current state
        final currentFavorites = state.valueOrNull ?? [];
        state = AsyncValue.data([favorite, ...currentFavorites]);
      },
      failure: (error) {
        // Optionally handle error
        throw error;
      },
    );
  }

  /// Remove restaurant from favorites
  Future<void> removeFavorite(int favoriteId) async {
    final repository = ref.read(favoriteRepositoryProvider);
    final result = await repository.removeFavorite(favoriteId);

    result.when(
      success: (_) {
        // Remove from current state
        final currentFavorites = state.valueOrNull ?? [];
        state = AsyncValue.data(
          currentFavorites.where((f) => f.id != favoriteId).toList(),
        );
      },
      failure: (error) {
        throw error;
      },
    );
  }

  /// Remove by restaurant ID
  Future<void> removeFavoriteByRestaurantId(int restaurantId) async {
    final favorites = state.valueOrNull ?? [];
    final favorite = favorites.where((f) => f.restaurantId == restaurantId).firstOrNull;

    if (favorite != null) {
      await removeFavorite(favorite.id);
    }
  }
}

/// Get favorite by restaurant ID
@riverpod
FavoriteModel? favoriteByRestaurantId(
  FavoriteByRestaurantIdRef ref,
  int restaurantId,
) {
  final favoritesAsync = ref.watch(favoriteListProvider);

  return favoritesAsync.when(
    data: (favorites) {
      return favorites.where((f) => f.restaurantId == restaurantId).firstOrNull;
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Check if restaurant is favorited
@riverpod
bool isFavorited(IsFavoritedRef ref, int restaurantId) {
  final favorite = ref.watch(favoriteByRestaurantIdProvider(restaurantId));
  return favorite != null;
}

/// Get total favorites count
@riverpod
int favoritesCount(FavoritesCountRef ref) {
  final favoritesAsync = ref.watch(favoriteListProvider);

  return favoritesAsync.when(
    data: (favorites) => favorites.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}
