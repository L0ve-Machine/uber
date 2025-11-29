import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/coupon_model.dart';
import '../data/repositories/coupon_repository.dart';
import '../data/services/coupon_api_service.dart';

part 'coupon_provider.g.dart';

/// CouponApiService provider
@riverpod
CouponApiService couponApiService(CouponApiServiceRef ref) {
  return CouponApiService(ref.watch(dioProvider));
}

/// CouponRepository provider
@riverpod
CouponRepository couponRepository(CouponRepositoryRef ref) {
  return CouponRepository(
    apiService: ref.watch(couponApiServiceProvider),
  );
}

/// Available coupons provider
@riverpod
class AvailableCoupons extends _$AvailableCoupons {
  @override
  Future<List<CouponModel>> build() async {
    return _fetchAvailableCoupons();
  }

  Future<List<CouponModel>> _fetchAvailableCoupons() async {
    final repository = ref.read(couponRepositoryProvider);
    final result = await repository.getAvailableCoupons();

    return result.when(
      success: (coupons) => coupons,
      failure: (error) => throw Exception(error.message),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAvailableCoupons());
  }
}

/// Applied coupon state
class AppliedCouponState {
  final CouponModel? coupon;
  final int discount;
  final bool isLoading;
  final String? error;

  const AppliedCouponState({
    this.coupon,
    this.discount = 0,
    this.isLoading = false,
    this.error,
  });

  AppliedCouponState copyWith({
    CouponModel? coupon,
    int? discount,
    bool? isLoading,
    String? error,
    bool clearCoupon = false,
  }) {
    return AppliedCouponState(
      coupon: clearCoupon ? null : (coupon ?? this.coupon),
      discount: clearCoupon ? 0 : (discount ?? this.discount),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Applied coupon notifier
@riverpod
class AppliedCoupon extends _$AppliedCoupon {
  @override
  AppliedCouponState build() {
    return const AppliedCouponState();
  }

  /// Validate and apply a coupon
  Future<bool> applyCoupon({
    required String code,
    required double subtotal,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(couponRepositoryProvider);
    final result = await repository.validateCoupon(
      code: code,
      subtotal: subtotal,
    );

    return result.when(
      success: (response) {
        state = AppliedCouponState(
          coupon: response.coupon,
          discount: response.discount,
          isLoading: false,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
    );
  }

  /// Remove applied coupon
  void removeCoupon() {
    state = const AppliedCouponState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
