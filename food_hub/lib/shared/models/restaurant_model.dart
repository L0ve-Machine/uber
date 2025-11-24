import 'package:json_annotation/json_annotation.dart';

part 'restaurant_model.g.dart';

@JsonSerializable()
class RestaurantModel {
  final int id;
  final String email;
  final String name;
  final String? description;
  final String category;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final double rating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'min_order_amount')
  final double minOrderAmount;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'delivery_time_minutes')
  final int deliveryTimeMinutes;
  @JsonKey(name: 'delivery_radius_km')
  final double deliveryRadiusKm;
  @JsonKey(name: 'is_open')
  final bool isOpen;
  @JsonKey(name: 'is_approved')
  final bool isApproved;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  RestaurantModel({
    required this.id,
    required this.email,
    required this.name,
    this.description,
    required this.category,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    this.logoUrl,
    required this.rating,
    required this.totalReviews,
    required this.minOrderAmount,
    required this.deliveryFee,
    required this.deliveryTimeMinutes,
    required this.deliveryRadiusKm,
    required this.isOpen,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantModelFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantModelToJson(this);
}
