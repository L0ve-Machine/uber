import 'package:json_annotation/json_annotation.dart';

part 'driver_model.g.dart';

@JsonSerializable()
class DriverModel {
  final int id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String phone;
  @JsonKey(name: 'vehicle_type')
  final String vehicleType;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'stripe_account_id')
  final String? stripeAccountId;
  @JsonKey(name: 'stripe_onboarding_completed')
  final bool stripeOnboardingCompleted;
  @JsonKey(name: 'stripe_payouts_enabled')
  final bool stripePayoutsEnabled;
  @JsonKey(name: 'base_payout_per_delivery')
  final double basePayoutPerDelivery;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    this.licenseNumber,
    required this.isOnline,
    this.stripeAccountId,
    required this.stripeOnboardingCompleted,
    required this.stripePayoutsEnabled,
    required this.basePayoutPerDelivery,
    required this.createdAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverModelToJson(this);

  /// Stripeが完全に設定されているか
  bool get isStripeFullySetup =>
      stripeOnboardingCompleted && stripePayoutsEnabled;

  /// Stripe設定が不完全な理由を返す
  String? get stripeSetupIssue {
    if (stripeAccountId == null) {
      return 'Stripe登録が完了していません';
    }
    if (!stripeOnboardingCompleted) {
      return 'オンボーディングが未完了です';
    }
    if (!stripePayoutsEnabled) {
      return '支払い受取設定が未完了です';
    }
    return null;
  }
}
