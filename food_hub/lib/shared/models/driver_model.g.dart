// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverModel _$DriverModelFromJson(Map<String, dynamic> json) => DriverModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      vehicleType: json['vehicle_type'] as String,
      licenseNumber: json['license_number'] as String?,
      isOnline: json['is_online'] as bool,
      stripeAccountId: json['stripe_account_id'] as String?,
      stripeOnboardingCompleted: json['stripe_onboarding_completed'] as bool,
      stripePayoutsEnabled: json['stripe_payouts_enabled'] as bool,
      basePayoutPerDelivery:
          (json['base_payout_per_delivery'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DriverModelToJson(DriverModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'vehicle_type': instance.vehicleType,
      'license_number': instance.licenseNumber,
      'is_online': instance.isOnline,
      'stripe_account_id': instance.stripeAccountId,
      'stripe_onboarding_completed': instance.stripeOnboardingCompleted,
      'stripe_payouts_enabled': instance.stripePayoutsEnabled,
      'base_payout_per_delivery': instance.basePayoutPerDelivery,
      'created_at': instance.createdAt.toIso8601String(),
    };
