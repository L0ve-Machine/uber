import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';

/// Order API Service
class OrderApiService {
  final Dio _dio;

  OrderApiService(this._dio);

  /// Create new order
  Future<ApiResult<OrderModel>> createOrder({
    required int restaurantId,
    required int deliveryAddressId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: {
          'restaurant_id': restaurantId,
          'delivery_address_id': deliveryAddressId,
          'items': items,
          'payment_method': paymentMethod,
          if (specialInstructions != null)
            'special_instructions': specialInstructions,
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
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

  /// Get customer's orders
  Future<ApiResult<List<OrderModel>>> getOrders({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/orders',
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

  /// Get order by ID
  Future<ApiResult<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _dio.get('/orders/$id');

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

  /// Cancel order
  Future<ApiResult<OrderModel>> cancelOrder(int id) async {
    try {
      final response = await _dio.patch('/orders/$id/cancel');

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
}
