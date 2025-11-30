import 'package:json_annotation/json_annotation.dart';

part 'menu_item_model.g.dart';

/// Helper function to parse double values that might come as String from MySQL
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

@JsonSerializable()
class MenuItemModel {
  final int id;
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;
  final String name;
  final String? description;
  @JsonKey(fromJson: _parseDouble)
  final double price;
  final String category;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final List<MenuItemOptionModel>? options;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.options,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) =>
      _$MenuItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemModelToJson(this);
}

@JsonSerializable()
class MenuItemOptionModel {
  final int id;
  @JsonKey(name: 'menu_item_id')
  final int menuItemId;
  @JsonKey(name: 'option_group_name')
  final String optionGroupName;
  @JsonKey(name: 'option_name')
  final String optionName;
  @JsonKey(name: 'additional_price', fromJson: _parseDouble)
  final double additionalPrice;

  MenuItemOptionModel({
    required this.id,
    required this.menuItemId,
    required this.optionGroupName,
    required this.optionName,
    required this.additionalPrice,
  });

  factory MenuItemOptionModel.fromJson(Map<String, dynamic> json) =>
      _$MenuItemOptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemOptionModelToJson(this);
}
