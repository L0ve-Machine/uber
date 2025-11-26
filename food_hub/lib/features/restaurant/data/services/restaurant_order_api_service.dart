import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';
import '../../models/restaurant_stats_model.dart';

/// Restaurant Order API Service
class RestaurantOrderApiService {
  final Dio _dio;

  RestaurantOrderApiService(this._dio);

  /// Get restaurant's orders
  Future<ApiResult<List<OrderModel>>> getOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/restaurant/orders',
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

  /// Get order detail
  Future<ApiResult<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _dio.get('/restaurant/orders/$id');

      if (response.statusCode == 200) {
        final order = OrderModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(order);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Accept order
  Future<ApiResult<OrderModel>> acceptOrder(int id) async {
    try {
      final response = await _dio.patch('/restaurant/orders/$id/accept');

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

  /// Reject order
  Future<ApiResult<OrderModel>> rejectOrder(int id, {String? reason}) async {
    try {
      final response = await _dio.patch(
        '/restaurant/orders/$id/reject',
        data: reason != null ? {'reason': reason} : null,
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

  /// Update order status (preparing, ready)
  Future<ApiResult<OrderModel>> updateOrderStatus(int id, String status) async {
    try {
      final response = await _dio.patch(
        '/restaurant/orders/$id/status',
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

  /// Get restaurant statistics
  Future<ApiResult<RestaurantStatsModel>> getStats({String period = 'today'}) async {
    try {
      final response = await _dio.get(
        '/restaurant/stats',
        queryParameters: {'period': period},
      );

      if (response.statusCode == 200) {
        final stats = RestaurantStatsModel.fromJson(
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
