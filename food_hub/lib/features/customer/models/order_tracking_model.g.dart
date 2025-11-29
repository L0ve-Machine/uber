// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_tracking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTrackingModel _$OrderTrackingModelFromJson(Map<String, dynamic> json) =>
    OrderTrackingModel(
      orderId: (json['orderId'] as num).toInt(),
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      isDriverAssigned: json['isDriverAssigned'] as bool,
      isCurrentlyDeliveringToYou: json['isCurrentlyDeliveringToYou'] as bool?,
      deliverySequence: (json['deliverySequence'] as num?)?.toInt(),
      remainingDeliveries: (json['remainingDeliveries'] as num?)?.toInt(),
      totalOrdersInBatch: (json['totalOrdersInBatch'] as num?)?.toInt(),
      driverLocation: json['driverLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['driverLocation'] as Map<String, dynamic>),
      driverInfo: json['driverInfo'] == null
          ? null
          : DriverInfo.fromJson(json['driverInfo'] as Map<String, dynamic>),
      restaurantLocation: json['restaurantLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['restaurantLocation'] as Map<String, dynamic>),
      deliveryLocation: json['deliveryLocation'] == null
          ? null
          : LocationInfo.fromJson(
              json['deliveryLocation'] as Map<String, dynamic>),
      message: json['message'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] == null
          ? null
          : DateTime.parse(json['acceptedAt'] as String),
      pickedUpAt: json['pickedUpAt'] == null
          ? null
          : DateTime.parse(json['pickedUpAt'] as String),
      estimatedDelivery: json['estimatedDelivery'] == null
          ? null
          : DateTime.parse(json['estimatedDelivery'] as String),
    );

Map<String, dynamic> _$OrderTrackingModelToJson(OrderTrackingModel instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'orderNumber': instance.orderNumber,
      'status': instance.status,
      'isDriverAssigned': instance.isDriverAssigned,
      'isCurrentlyDeliveringToYou': instance.isCurrentlyDeliveringToYou,
      'deliverySequence': instance.deliverySequence,
      'remainingDeliveries': instance.remainingDeliveries,
      'totalOrdersInBatch': instance.totalOrdersInBatch,
      'driverLocation': instance.driverLocation,
      'driverInfo': instance.driverInfo,
      'restaurantLocation': instance.restaurantLocation,
      'deliveryLocation': instance.deliveryLocation,
      'message': instance.message,
      'createdAt': instance.createdAt?.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'pickedUpAt': instance.pickedUpAt?.toIso8601String(),
      'estimatedDelivery': instance.estimatedDelivery?.toIso8601String(),
    };

LocationInfo _$LocationInfoFromJson(Map<String, dynamic> json) => LocationInfo(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
      address: json['address'] as String?,
      lastUpdate: json['lastUpdate'] == null
          ? null
          : DateTime.parse(json['lastUpdate'] as String),
    );

Map<String, dynamic> _$LocationInfoToJson(LocationInfo instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'name': instance.name,
      'address': instance.address,
      'lastUpdate': instance.lastUpdate?.toIso8601String(),
    };

DriverInfo _$DriverInfoFromJson(Map<String, dynamic> json) => DriverInfo(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$DriverInfoToJson(DriverInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phone': instance.phone,
    };
