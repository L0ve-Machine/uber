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
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeOnboardingCompleted:
          json['stripe_onboarding_completed'] as bool? ?? false,
      stripeChargesEnabled: json['stripe_charges_enabled'] as bool? ?? false,
      stripePayoutsEnabled: json['stripe_payouts_enabled'] as bool? ?? false,
      commissionRate: json['commission_rate'] == null
          ? 0.35
          : _parseDouble(json['commission_rate']),
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
      'stripe_account_id': instance.stripeAccountId,
      'stripe_onboarding_completed': instance.stripeOnboardingCompleted,
      'stripe_charges_enabled': instance.stripeChargesEnabled,
      'stripe_payouts_enabled': instance.stripePayoutsEnabled,
      'commission_rate': instance.commissionRate,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
