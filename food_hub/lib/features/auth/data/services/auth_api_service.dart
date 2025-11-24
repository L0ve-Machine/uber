import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/auth_models.dart';

/// Auth API Service
class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  /// Login
  Future<ApiResult<LoginResponse>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(loginResponse);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Register customer
  Future<ApiResult<RegisterResponse>> registerCustomer(
    RegisterCustomerRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register/customer',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final registerResponse = RegisterResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(registerResponse);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get current user
  Future<ApiResult<Map<String, dynamic>>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      if (response.statusCode == 200) {
        return Success(response.data as Map<String, dynamic>);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
