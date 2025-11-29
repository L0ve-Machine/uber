// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$couponApiServiceHash() => r'5d8674e9998f515e647dd56bc101b3fd8aedd564';

/// CouponApiService provider
///
/// Copied from [couponApiService].
@ProviderFor(couponApiService)
final couponApiServiceProvider = AutoDisposeProvider<CouponApiService>.internal(
  couponApiService,
  name: r'couponApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$couponApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CouponApiServiceRef = AutoDisposeProviderRef<CouponApiService>;
String _$couponRepositoryHash() => r'76adb87227cb21aaa5da5d56c965943c8c1546c5';

/// CouponRepository provider
///
/// Copied from [couponRepository].
@ProviderFor(couponRepository)
final couponRepositoryProvider = AutoDisposeProvider<CouponRepository>.internal(
  couponRepository,
  name: r'couponRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$couponRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CouponRepositoryRef = AutoDisposeProviderRef<CouponRepository>;
String _$availableCouponsHash() => r'89efcfc06e45cf544ca88b479adb796849858985';

/// Available coupons provider
///
/// Copied from [AvailableCoupons].
@ProviderFor(AvailableCoupons)
final availableCouponsProvider = AutoDisposeAsyncNotifierProvider<
    AvailableCoupons, List<CouponModel>>.internal(
  AvailableCoupons.new,
  name: r'availableCouponsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableCouponsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AvailableCoupons = AutoDisposeAsyncNotifier<List<CouponModel>>;
String _$appliedCouponHash() => r'01ce4d650737b666a193bee053c3935b638b4360';

/// Applied coupon notifier
///
/// Copied from [AppliedCoupon].
@ProviderFor(AppliedCoupon)
final appliedCouponProvider =
    AutoDisposeNotifierProvider<AppliedCoupon, AppliedCouponState>.internal(
  AppliedCoupon.new,
  name: r'appliedCouponProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appliedCouponHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppliedCoupon = AutoDisposeNotifier<AppliedCouponState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
