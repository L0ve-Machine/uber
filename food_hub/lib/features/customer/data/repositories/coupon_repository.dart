import '../../../../core/network/api_result.dart';
import '../../../../shared/models/coupon_model.dart';
import '../services/coupon_api_service.dart';

class CouponRepository {
  final CouponApiService _apiService;

  CouponRepository({required CouponApiService apiService})
      : _apiService = apiService;

  /// Validate a coupon code
  Future<ApiResult<ValidateCouponResponse>> validateCoupon({
    required String code,
    required double subtotal,
  }) {
    return _apiService.validateCoupon(code: code, subtotal: subtotal);
  }

  /// Get available coupons for customer
  Future<ApiResult<List<CouponModel>>> getAvailableCoupons() {
    return _apiService.getAvailableCoupons();
  }
}
