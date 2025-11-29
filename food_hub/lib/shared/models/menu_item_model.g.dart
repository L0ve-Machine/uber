// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item_model.dart';

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

MenuItemModel _$MenuItemModelFromJson(Map<String, dynamic> json) =>
    MenuItemModel(
      id: _parseInt(json['id']),
      restaurantId: _parseInt(json['restaurant_id']),
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _parseDouble(json['price']),
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => MenuItemOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MenuItemModelToJson(MenuItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurant_id': instance.restaurantId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'image_url': instance.imageUrl,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'options': instance.options,
    };

MenuItemOptionModel _$MenuItemOptionModelFromJson(Map<String, dynamic> json) =>
    MenuItemOptionModel(
      id: _parseInt(json['id']),
      menuItemId: _parseInt(json['menu_item_id']),
      optionGroupName: json['option_group_name'] as String,
      optionName: json['option_name'] as String,
      additionalPrice: _parseDouble(json['additional_price']),
    );

Map<String, dynamic> _$MenuItemOptionModelToJson(
        MenuItemOptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'menu_item_id': instance.menuItemId,
      'option_group_name': instance.optionGroupName,
      'option_name': instance.optionName,
      'additional_price': instance.additionalPrice,
    };
