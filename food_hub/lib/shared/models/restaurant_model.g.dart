// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantModel _$RestaurantModelFromJson(Map<String, dynamic> json) =>
    RestaurantModel(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      coverImageUrl: json['cover_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      rating: (json['rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      minOrderAmount: (json['min_order_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      deliveryTimeMinutes: (json['delivery_time_minutes'] as num).toInt(),
      deliveryRadiusKm: (json['delivery_radius_km'] as num).toDouble(),
      isOpen: json['is_open'] as bool,
      isApproved: json['is_approved'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RestaurantModelToJson(RestaurantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'phone': instance.phone,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cover_image_url': instance.coverImageUrl,
      'logo_url': instance.logoUrl,
      'rating': instance.rating,
      'total_reviews': instance.totalReviews,
      'min_order_amount': instance.minOrderAmount,
      'delivery_fee': instance.deliveryFee,
      'delivery_time_minutes': instance.deliveryTimeMinutes,
      'delivery_radius_km': instance.deliveryRadiusKm,
      'is_open': instance.isOpen,
      'is_approved': instance.isApproved,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
