import 'package:json_annotation/json_annotation.dart';

part 'order_tracking_model.g.dart';

/// 注文追跡情報モデル
@JsonSerializable()
class OrderTrackingModel {
  @JsonKey(name: 'orderId')
  final int orderId;

  @JsonKey(name: 'orderNumber')
  final String orderNumber;

  final String status;

  @JsonKey(name: 'isDriverAssigned')
  final bool isDriverAssigned;

  @JsonKey(name: 'isCurrentlyDeliveringToYou')
  final bool? isCurrentlyDeliveringToYou;

  @JsonKey(name: 'deliverySequence')
  final int? deliverySequence;

  @JsonKey(name: 'remainingDeliveries')
  final int? remainingDeliveries;

  @JsonKey(name: 'totalOrdersInBatch')
  final int? totalOrdersInBatch;

  @JsonKey(name: 'driverLocation')
  final LocationInfo? driverLocation;

  @JsonKey(name: 'driverInfo')
  final DriverInfo? driverInfo;

  @JsonKey(name: 'restaurantLocation')
  final LocationInfo? restaurantLocation;

  @JsonKey(name: 'deliveryLocation')
  final LocationInfo? deliveryLocation;

  final String? message;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'acceptedAt')
  final DateTime? acceptedAt;

  @JsonKey(name: 'pickedUpAt')
  final DateTime? pickedUpAt;

  @JsonKey(name: 'estimatedDelivery')
  final DateTime? estimatedDelivery;

  OrderTrackingModel({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.isDriverAssigned,
    this.isCurrentlyDeliveringToYou,
    this.deliverySequence,
    this.remainingDeliveries,
    this.totalOrdersInBatch,
    this.driverLocation,
    this.driverInfo,
    this.restaurantLocation,
    this.deliveryLocation,
    this.message,
    this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.estimatedDelivery,
  });

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json) =>
      _$OrderTrackingModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTrackingModelToJson(this);
}

/// 位置情報モデル
@JsonSerializable()
class LocationInfo {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;
  @JsonKey(name: 'lastUpdate')
  final DateTime? lastUpdate;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
    this.lastUpdate,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$LocationInfoToJson(this);
}

/// 配達員情報モデル
@JsonSerializable()
class DriverInfo {
  final int id;
  @JsonKey(name: 'fullName')
  final String? fullName;
  final String? phone;

  DriverInfo({
    required this.id,
    this.fullName,
    this.phone,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) =>
      _$DriverInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DriverInfoToJson(this);
}
