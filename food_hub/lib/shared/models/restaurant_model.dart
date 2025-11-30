import 'package:json_annotation/json_annotation.dart';

part 'restaurant_model.g.dart';

/// Helper function to parse double values that might come as String from MySQL
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Helper function to parse int values that might come as String from MySQL
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class RestaurantModel {
  final int id;
  final String email;
  final String name;
  final String? description;
  final String category;
  final String phone;
  final String address;
  @JsonKey(fromJson: _parseDouble)
  final double latitude;
  @JsonKey(fromJson: _parseDouble)
  final double longitude;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(fromJson: _parseDouble)
  final double rating;
  @JsonKey(name: 'total_reviews', fromJson: _parseInt)
  final int totalReviews;
  @JsonKey(name: 'min_order_amount', fromJson: _parseDouble)
  final double minOrderAmount;
  @JsonKey(name: 'delivery_fee', fromJson: _parseDouble)
  final double deliveryFee;
  @JsonKey(name: 'delivery_time_minutes', fromJson: _parseInt)
  final int deliveryTimeMinutes;
  @JsonKey(name: 'delivery_radius_km', fromJson: _parseDouble)
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
