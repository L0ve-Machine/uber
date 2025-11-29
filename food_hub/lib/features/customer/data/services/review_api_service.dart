import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/review_model.dart';

class ReviewApiService {
  final Dio _dio;

  ReviewApiService(this._dio);

  /// Get reviews for a restaurant
  Future<ApiResult<ReviewListResponse>> getRestaurantReviews({
    required int restaurantId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/reviews/restaurant/$restaurantId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final data = ReviewListResponse.fromJson(response.data['data']);
        return Success(data);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'レビューの取得に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Create a review
  Future<ApiResult<ReviewModel>> createReview(CreateReviewRequest request) async {
    try {
      final response = await _dio.post(
        '/reviews',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        final review = ReviewModel.fromJson(response.data['data']);
        return Success(review);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'レビューの投稿に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Get my reviews
  Future<ApiResult<List<ReviewModel>>> getMyReviews({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/reviews/my',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] == true) {
        final reviews = (response.data['data']['reviews'] as List)
            .map((json) => ReviewModel.fromJson(json))
            .toList();
        return Success(reviews);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'レビューの取得に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Check if order can be reviewed
  Future<ApiResult<CanReviewResponse>> canReview(int orderId) async {
    try {
      final response = await _dio.get('/reviews/can-review/$orderId');

      if (response.data['success'] == true) {
        final data = CanReviewResponse.fromJson(response.data['data']);
        return Success(data);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'エラーが発生しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Update a review
  Future<ApiResult<ReviewModel>> updateReview(int id, UpdateReviewRequest request) async {
    try {
      final response = await _dio.put(
        '/reviews/$id',
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        final review = ReviewModel.fromJson(response.data['data']);
        return Success(review);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'レビューの更新に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Delete a review
  Future<ApiResult<void>> deleteReview(int id) async {
    try {
      final response = await _dio.delete('/reviews/$id');

      if (response.data['success'] == true) {
        return const Success(null);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'レビューの削除に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }
}
