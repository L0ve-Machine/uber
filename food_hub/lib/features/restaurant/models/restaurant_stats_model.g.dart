// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantStatsModel _$RestaurantStatsModelFromJson(
        Map<String, dynamic> json) =>
    RestaurantStatsModel(
      period: json['period'] as String,
      totalOrders: (json['total_orders'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      statusCounts: Map<String, int>.from(json['status_counts'] as Map),
    );

Map<String, dynamic> _$RestaurantStatsModelToJson(
        RestaurantStatsModel instance) =>
    <String, dynamic>{
      'period': instance.period,
      'total_orders': instance.totalOrders,
      'total_revenue': instance.totalRevenue,
      'average_order_value': instance.averageOrderValue,
      'status_counts': instance.statusCounts,
    };
