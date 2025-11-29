// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteModel _$FavoriteModelFromJson(Map<String, dynamic> json) =>
    FavoriteModel(
      id: (json['id'] as num).toInt(),
      customerId: (json['customer_id'] as num).toInt(),
      restaurantId: (json['restaurant_id'] as num).toInt(),
      restaurant: json['restaurant'] == null
          ? null
          : RestaurantModel.fromJson(
              json['restaurant'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FavoriteModelToJson(FavoriteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customer_id': instance.customerId,
      'restaurant_id': instance.restaurantId,
      'restaurant': instance.restaurant,
      'created_at': instance.createdAt.toIso8601String(),
    };

FavoritesResponse _$FavoritesResponseFromJson(Map<String, dynamic> json) =>
    FavoritesResponse(
      favorites: (json['favorites'] as List<dynamic>)
          .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$FavoritesResponseToJson(FavoritesResponse instance) =>
    <String, dynamic>{
      'favorites': instance.favorites,
      'total': instance.total,
    };

AddFavoriteRequest _$AddFavoriteRequestFromJson(Map<String, dynamic> json) =>
    AddFavoriteRequest(
      restaurantId: (json['restaurant_id'] as num).toInt(),
    );

Map<String, dynamic> _$AddFavoriteRequestToJson(AddFavoriteRequest instance) =>
    <String, dynamic>{
      'restaurant_id': instance.restaurantId,
    };

AddFavoriteResponse _$AddFavoriteResponseFromJson(Map<String, dynamic> json) =>
    AddFavoriteResponse(
      message: json['message'] as String,
      favorite:
          FavoriteModel.fromJson(json['favorite'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AddFavoriteResponseToJson(
        AddFavoriteResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'favorite': instance.favorite,
    };
