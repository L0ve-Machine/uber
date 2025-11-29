import 'package:json_annotation/json_annotation.dart';
import 'restaurant_model.dart';

part 'favorite_model.g.dart';

@JsonSerializable()
class FavoriteModel {
  final int id;

  @JsonKey(name: 'customer_id')
  final int customerId;

  @JsonKey(name: 'restaurant_id')
  final int restaurantId;

  final RestaurantModel? restaurant;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.restaurant,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) =>
      _$FavoriteModelFromJson(json);

  Map<String, dynamic> toJson() => _$FavoriteModelToJson(this);
}

@JsonSerializable()
class FavoritesResponse {
  final List<FavoriteModel> favorites;
  final int total;

  FavoritesResponse({
    required this.favorites,
    required this.total,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoritesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FavoritesResponseToJson(this);
}

@JsonSerializable()
class AddFavoriteRequest {
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;

  AddFavoriteRequest({
    required this.restaurantId,
  });

  factory AddFavoriteRequest.fromJson(Map<String, dynamic> json) =>
      _$AddFavoriteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddFavoriteRequestToJson(this);
}

@JsonSerializable()
class AddFavoriteResponse {
  final String message;
  final FavoriteModel favorite;

  AddFavoriteResponse({
    required this.message,
    required this.favorite,
  });

  factory AddFavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$AddFavoriteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddFavoriteResponseToJson(this);
}
