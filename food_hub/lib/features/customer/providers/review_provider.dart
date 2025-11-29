import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/review_model.dart';
import '../data/repositories/review_repository.dart';
import '../data/services/review_api_service.dart';

part 'review_provider.g.dart';

/// ReviewApiService provider
@riverpod
ReviewApiService reviewApiService(ReviewApiServiceRef ref) {
  return ReviewApiService(ref.watch(dioProvider));
}

/// ReviewRepository provider
@riverpod
ReviewRepository reviewRepository(ReviewRepositoryRef ref) {
  return ReviewRepository(
    apiService: ref.watch(reviewApiServiceProvider),
  );
}

/// Restaurant reviews provider
@riverpod
class RestaurantReviews extends _$RestaurantReviews {
  late int _restaurantId;

  @override
  Future<ReviewListResponse> build(int restaurantId) async {
    _restaurantId = restaurantId;
    return _fetchReviews(restaurantId, 1);
  }

  Future<ReviewListResponse> _fetchReviews(int restaurantId, int page) async {
    final repository = ref.read(reviewRepositoryProvider);
    final result = await repository.getRestaurantReviews(
      restaurantId: restaurantId,
      page: page,
    );

    return result.when(
      success: (data) => data,
      failure: (error) => throw Exception(error.message),
    );
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final currentPage = currentState.pagination.page;
    final totalPages = currentState.pagination.totalPages;

    if (currentPage >= totalPages) return;

    final newData = await _fetchReviews(
      _restaurantId,
      currentPage + 1,
    );

    state = AsyncValue.data(ReviewListResponse(
      reviews: [...currentState.reviews, ...newData.reviews],
      pagination: newData.pagination,
      stats: newData.stats,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchReviews(_restaurantId, 1));
  }
}

/// My reviews provider
@riverpod
class MyReviews extends _$MyReviews {
  @override
  Future<List<ReviewModel>> build() async {
    return _fetchMyReviews();
  }

  Future<List<ReviewModel>> _fetchMyReviews() async {
    final repository = ref.read(reviewRepositoryProvider);
    final result = await repository.getMyReviews();

    return result.when(
      success: (reviews) => reviews,
      failure: (error) => throw Exception(error.message),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMyReviews());
  }

  void removeReview(int reviewId) {
    final currentReviews = state.valueOrNull;
    if (currentReviews == null) return;

    state = AsyncValue.data(
      currentReviews.where((r) => r.id != reviewId).toList(),
    );
  }
}

/// Can review check provider
@riverpod
Future<CanReviewResponse> canReview(CanReviewRef ref, int orderId) async {
  final repository = ref.read(reviewRepositoryProvider);
  final result = await repository.canReview(orderId);

  return result.when(
    success: (data) => data,
    failure: (error) => throw Exception(error.message),
  );
}

/// Create review notifier
@riverpod
class CreateReview extends _$CreateReview {
  @override
  AsyncValue<ReviewModel?> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> submit({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(reviewRepositoryProvider);
    final result = await repository.createReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
    );

    return result.when(
      success: (review) {
        state = AsyncValue.data(review);
        // Invalidate my reviews to refresh the list
        ref.invalidate(myReviewsProvider);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }
}

/// Update review notifier
@riverpod
class UpdateReview extends _$UpdateReview {
  @override
  AsyncValue<ReviewModel?> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> submit({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(reviewRepositoryProvider);
    final result = await repository.updateReview(
      id: reviewId,
      rating: rating,
      comment: comment,
    );

    return result.when(
      success: (review) {
        state = AsyncValue.data(review);
        // Invalidate my reviews to refresh the list
        ref.invalidate(myReviewsProvider);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }
}

/// Delete review notifier
@riverpod
class DeleteReview extends _$DeleteReview {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> delete(int reviewId) async {
    state = const AsyncValue.loading();

    final repository = ref.read(reviewRepositoryProvider);
    final result = await repository.deleteReview(reviewId);

    return result.when(
      success: (_) {
        state = const AsyncValue.data(null);
        // Remove from my reviews list
        ref.read(myReviewsProvider.notifier).removeReview(reviewId);
        return true;
      },
      failure: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return false;
      },
    );
  }
}
