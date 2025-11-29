import '../../../../core/network/api_result.dart';
import '../../../../shared/models/review_model.dart';
import '../services/review_api_service.dart';

class ReviewRepository {
  final ReviewApiService _apiService;

  ReviewRepository({required ReviewApiService apiService})
      : _apiService = apiService;

  /// Get reviews for a restaurant
  Future<ApiResult<ReviewListResponse>> getRestaurantReviews({
    required int restaurantId,
    int page = 1,
    int limit = 10,
  }) {
    return _apiService.getRestaurantReviews(
      restaurantId: restaurantId,
      page: page,
      limit: limit,
    );
  }

  /// Create a review
  Future<ApiResult<ReviewModel>> createReview({
    required int orderId,
    required int rating,
    String? comment,
  }) {
    return _apiService.createReview(CreateReviewRequest(
      orderId: orderId,
      rating: rating,
      comment: comment,
    ));
  }

  /// Get my reviews
  Future<ApiResult<List<ReviewModel>>> getMyReviews({
    int page = 1,
    int limit = 10,
  }) {
    return _apiService.getMyReviews(page: page, limit: limit);
  }

  /// Check if order can be reviewed
  Future<ApiResult<CanReviewResponse>> canReview(int orderId) {
    return _apiService.canReview(orderId);
  }

  /// Update a review
  Future<ApiResult<ReviewModel>> updateReview({
    required int id,
    required int rating,
    String? comment,
  }) {
    return _apiService.updateReview(id, UpdateReviewRequest(
      rating: rating,
      comment: comment,
    ));
  }

  /// Delete a review
  Future<ApiResult<void>> deleteReview(int id) {
    return _apiService.deleteReview(id);
  }
}
