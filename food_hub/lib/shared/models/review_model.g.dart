// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
      id: (json['id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      restaurantId: (json['restaurant_id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      customer: json['customer'] == null
          ? null
          : ReviewCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      restaurant: json['restaurant'] == null
          ? null
          : RestaurantModel.fromJson(
              json['restaurant'] as Map<String, dynamic>),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'restaurant_id': instance.restaurantId,
      'order_id': instance.orderId,
      'rating': instance.rating,
      'comment': instance.comment,
      'customer': instance.customer,
      'restaurant': instance.restaurant,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

ReviewCustomer _$ReviewCustomerFromJson(Map<String, dynamic> json) =>
    ReviewCustomer(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
    );

Map<String, dynamic> _$ReviewCustomerToJson(ReviewCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
    };

ReviewListResponse _$ReviewListResponseFromJson(Map<String, dynamic> json) =>
    ReviewListResponse(
      reviews: (json['reviews'] as List<dynamic>)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          ReviewPagination.fromJson(json['pagination'] as Map<String, dynamic>),
      stats: ReviewStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReviewListResponseToJson(ReviewListResponse instance) =>
    <String, dynamic>{
      'reviews': instance.reviews,
      'pagination': instance.pagination,
      'stats': instance.stats,
    };

ReviewPagination _$ReviewPaginationFromJson(Map<String, dynamic> json) =>
    ReviewPagination(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewPaginationToJson(ReviewPagination instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'totalPages': instance.totalPages,
    };

ReviewStats _$ReviewStatsFromJson(Map<String, dynamic> json) => ReviewStats(
      averageRating: json['averageRating'] as String?,
      totalReviews: (json['totalReviews'] as num).toInt(),
    );

Map<String, dynamic> _$ReviewStatsToJson(ReviewStats instance) =>
    <String, dynamic>{
      'averageRating': instance.averageRating,
      'totalReviews': instance.totalReviews,
    };

CanReviewResponse _$CanReviewResponseFromJson(Map<String, dynamic> json) =>
    CanReviewResponse(
      canReview: json['canReview'] as bool,
      hasReview: json['hasReview'] as bool,
      review: json['review'] == null
          ? null
          : ReviewModel.fromJson(json['review'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CanReviewResponseToJson(CanReviewResponse instance) =>
    <String, dynamic>{
      'canReview': instance.canReview,
      'hasReview': instance.hasReview,
      'review': instance.review,
    };

CreateReviewRequest _$CreateReviewRequestFromJson(Map<String, dynamic> json) =>
    CreateReviewRequest(
      orderId: (json['order_id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$CreateReviewRequestToJson(
        CreateReviewRequest instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'rating': instance.rating,
      'comment': instance.comment,
    };

UpdateReviewRequest _$UpdateReviewRequestFromJson(Map<String, dynamic> json) =>
    UpdateReviewRequest(
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$UpdateReviewRequestToJson(
        UpdateReviewRequest instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'comment': instance.comment,
    };
