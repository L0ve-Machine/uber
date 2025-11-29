import 'package:json_annotation/json_annotation.dart';
import 'restaurant_model.dart';

part 'review_model.g.dart';

@JsonSerializable()
class ReviewModel {
  final int id;

  @JsonKey(name: 'customer_id')
  final int customerId;

  @JsonKey(name: 'restaurant_id')
  final int restaurantId;

  @JsonKey(name: 'order_id')
  final int orderId;

  final int rating;

  final String? comment;

  final ReviewCustomer? customer;

  final RestaurantModel? restaurant;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.orderId,
    required this.rating,
    this.comment,
    this.customer,
    this.restaurant,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);
}

@JsonSerializable()
class ReviewCustomer {
  final int id;

  @JsonKey(name: 'full_name')
  final String fullName;

  ReviewCustomer({
    required this.id,
    required this.fullName,
  });

  factory ReviewCustomer.fromJson(Map<String, dynamic> json) =>
      _$ReviewCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewCustomerToJson(this);
}

@JsonSerializable()
class ReviewListResponse {
  final List<ReviewModel> reviews;
  final ReviewPagination pagination;
  final ReviewStats stats;

  ReviewListResponse({
    required this.reviews,
    required this.pagination,
    required this.stats,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) =>
      _$ReviewListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewListResponseToJson(this);
}

@JsonSerializable()
class ReviewPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ReviewPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ReviewPagination.fromJson(Map<String, dynamic> json) =>
      _$ReviewPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewPaginationToJson(this);
}

@JsonSerializable()
class ReviewStats {
  final String? averageRating;
  final int totalReviews;

  ReviewStats({
    this.averageRating,
    required this.totalReviews,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) =>
      _$ReviewStatsFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewStatsToJson(this);
}

@JsonSerializable()
class CanReviewResponse {
  final bool canReview;
  final bool hasReview;
  final ReviewModel? review;

  CanReviewResponse({
    required this.canReview,
    required this.hasReview,
    this.review,
  });

  factory CanReviewResponse.fromJson(Map<String, dynamic> json) =>
      _$CanReviewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CanReviewResponseToJson(this);
}

@JsonSerializable()
class CreateReviewRequest {
  @JsonKey(name: 'order_id')
  final int orderId;

  final int rating;

  final String? comment;

  CreateReviewRequest({
    required this.orderId,
    required this.rating,
    this.comment,
  });

  factory CreateReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReviewRequestToJson(this);
}

@JsonSerializable()
class UpdateReviewRequest {
  final int rating;

  final String? comment;

  UpdateReviewRequest({
    required this.rating,
    this.comment,
  });

  factory UpdateReviewRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateReviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateReviewRequestToJson(this);
}
