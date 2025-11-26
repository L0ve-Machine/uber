import 'package:json_annotation/json_annotation.dart';

part 'restaurant_stats_model.g.dart';

@JsonSerializable()
class RestaurantStatsModel {
  final String period;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  @JsonKey(name: 'status_counts')
  final Map<String, int> statusCounts;

  RestaurantStatsModel({
    required this.period,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.statusCounts,
  });

  factory RestaurantStatsModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantStatsModelToJson(this);
}
