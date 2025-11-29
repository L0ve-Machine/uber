// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_model.dart';

// Helper function to parse double from String or num
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Helper function to parse int from String or num
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

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
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      coverImageUrl: json['cover_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      rating: _parseDouble(json['rating']),
      totalReviews: _parseInt(json['total_reviews']),
      minOrderAmount: _parseDouble(json['min_order_amount']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      deliveryTimeMinutes: _parseInt(json['delivery_time_minutes']),
      deliveryRadiusKm: _parseDouble(json['delivery_radius_km']),
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
