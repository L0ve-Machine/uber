import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

/// Helper function to parse double values that might come as String from MySQL
double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class AddressModel {
  final int id;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'address_line')
  final String addressLine;
  final String city;
  @JsonKey(name: 'postal_code')
  final String postalCode;
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? latitude;
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? longitude;
  @JsonKey(name: 'is_default')
  final bool isDefault;
  final String label;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.customerId,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  /// Full address string
  String get fullAddress => '$addressLine, $city $postalCode';
}
