import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';
import '../../models/restaurant_stats_model.dart';
import '../services/restaurant_order_api_service.dart';

/// Restaurant Order Repository
class RestaurantOrderRepository {
  final RestaurantOrderApiService _apiService;

  RestaurantOrderRepository({required RestaurantOrderApiService apiService})
      : _apiService = apiService;

  /// Get restaurant's orders
  Future<ApiResult<List<OrderModel>>> getOrders({String? status}) async {
    return await _apiService.getOrders(status: status);
  }

  /// Get order by ID
  Future<ApiResult<OrderModel>> getOrderById(int id) async {
    return await _apiService.getOrderById(id);
  }

  /// Accept order
  Future<ApiResult<OrderModel>> acceptOrder(int id) async {
    return await _apiService.acceptOrder(id);
  }

  /// Reject order
  Future<ApiResult<OrderModel>> rejectOrder(int id, {String? reason}) async {
    return await _apiService.rejectOrder(id, reason: reason);
  }

  /// Update order status to preparing
  Future<ApiResult<OrderModel>> startPreparing(int id) async {
    return await _apiService.updateOrderStatus(id, 'preparing');
  }

  /// Update order status to ready
  Future<ApiResult<OrderModel>> markReady(int id) async {
    return await _apiService.updateOrderStatus(id, 'ready');
  }

  /// Get restaurant statistics
  Future<ApiResult<RestaurantStatsModel>> getStats({String period = 'today'}) async {
    return await _apiService.getStats(period: period);
  }
}
