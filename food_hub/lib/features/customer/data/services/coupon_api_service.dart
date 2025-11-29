import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/coupon_model.dart';

class CouponApiService {
  final Dio _dio;

  CouponApiService(this._dio);

  /// Validate a coupon code
  Future<ApiResult<ValidateCouponResponse>> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    try {
      final response = await _dio.post(
        '/coupons/validate',
        data: {
          'code': code,
          'subtotal': subtotal,
        },
      );

      if (response.data['success'] == true) {
        final data = ValidateCouponResponse.fromJson(response.data['data']);
        return Success(data);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'クーポンの検証に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }

  /// Get available coupons for customer
  Future<ApiResult<List<CouponModel>>> getAvailableCoupons() async {
    try {
      final response = await _dio.get('/coupons/available');

      if (response.data['success'] == true) {
        final coupons = (response.data['data'] as List)
            .map((json) => CouponModel.fromJson(json))
            .toList();
        return Success(coupons);
      } else {
        return Failure(ApiError(
          message: response.data['message'] ?? 'クーポンの取得に失敗しました',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: '予期せぬエラーが発生しました'));
    }
  }
}
