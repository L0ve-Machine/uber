import 'package:json_annotation/json_annotation.dart';

part 'driver_stats_model.g.dart';

@JsonSerializable()
class DriverStatsModel {
  final String period;
  @JsonKey(name: 'total_deliveries')
  final int totalDeliveries;
  @JsonKey(name: 'total_earnings')
  final double totalEarnings;
  @JsonKey(name: 'average_earning')
  final double averageEarning;

  DriverStatsModel({
    required this.period,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.averageEarning,
  });

  factory DriverStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DriverStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverStatsModelToJson(this);
}
