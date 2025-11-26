// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverStatsModel _$DriverStatsModelFromJson(Map<String, dynamic> json) =>
    DriverStatsModel(
      period: json['period'] as String,
      totalDeliveries: (json['total_deliveries'] as num).toInt(),
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      averageEarning: (json['average_earning'] as num).toDouble(),
    );

Map<String, dynamic> _$DriverStatsModelToJson(DriverStatsModel instance) =>
    <String, dynamic>{
      'period': instance.period,
      'total_deliveries': instance.totalDeliveries,
      'total_earnings': instance.totalEarnings,
      'average_earning': instance.averageEarning,
    };
