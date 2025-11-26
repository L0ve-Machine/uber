import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';
import '../../models/driver_stats_model.dart';

/// Driver API Service
class DriverApiService {
  final Dio _dio;

  DriverApiService(this._dio);

  /// Get available orders for pickup
  Future<ApiResult<List<OrderModel>>> getAvailableOrders() async {
    try {
      final response = await _dio.get('/driver/available-orders');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final ordersList = data['orders'] as List<dynamic>;

        final orders = ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(orders);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get driver's assigned orders
  Future<ApiResult<List<OrderModel>>> getDriverOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/driver/orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final ordersList = data['orders'] as List<dynamic>;

        final orders = ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(orders);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Accept delivery
  Future<ApiResult<OrderModel>> acceptDelivery(int orderId) async {
    try {
      final response = await _dio.post('/driver/orders/$orderId/accept');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);
        return Success(order);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Update delivery status (delivering, delivered)
  Future<ApiResult<OrderModel>> updateDeliveryStatus(int orderId, String status) async {
    try {
      final response = await _dio.patch(
        '/driver/orders/$orderId/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final order = OrderModel.fromJson(data['order'] as Map<String, dynamic>);
        return Success(order);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Update driver location
  Future<ApiResult<void>> updateLocation(double latitude, double longitude) async {
    try {
      final response = await _dio.patch(
        '/driver/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        return Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Toggle online status
  Future<ApiResult<bool>> toggleOnlineStatus(bool isOnline) async {
    try {
      final response = await _dio.patch(
        '/driver/online',
        data: {'is_online': isOnline},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Success(data['is_online'] as bool);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Get driver statistics
  Future<ApiResult<DriverStatsModel>> getStats({String period = 'today'}) async {
    try {
      final response = await _dio.get(
        '/driver/stats',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200) {
        final stats = DriverStatsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(stats);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
