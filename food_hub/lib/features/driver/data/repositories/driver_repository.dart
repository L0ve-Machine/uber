import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';
import '../../models/driver_stats_model.dart';
import '../services/driver_api_service.dart';

/// Driver Repository
class DriverRepository {
  final DriverApiService _apiService;

  DriverRepository({required DriverApiService apiService})
      : _apiService = apiService;

  /// Get available orders for pickup
  Future<ApiResult<List<OrderModel>>> getAvailableOrders() async {
    return await _apiService.getAvailableOrders();
  }

  /// Get driver's assigned orders
  Future<ApiResult<List<OrderModel>>> getDriverOrders({String? status}) async {
    return await _apiService.getDriverOrders(status: status);
  }

  /// Accept delivery
  Future<ApiResult<OrderModel>> acceptDelivery(int orderId) async {
    return await _apiService.acceptDelivery(orderId);
  }

  /// Start delivering
  Future<ApiResult<OrderModel>> startDelivering(int orderId) async {
    return await _apiService.updateDeliveryStatus(orderId, 'delivering');
  }

  /// Complete delivery
  Future<ApiResult<OrderModel>> completeDelivery(int orderId) async {
    return await _apiService.updateDeliveryStatus(orderId, 'delivered');
  }

  /// Update driver location
  Future<ApiResult<void>> updateLocation(double latitude, double longitude) async {
    return await _apiService.updateLocation(latitude, longitude);
  }

  /// Toggle online status
  Future<ApiResult<bool>> toggleOnlineStatus(bool isOnline) async {
    return await _apiService.toggleOnlineStatus(isOnline);
  }

  /// Get driver statistics
  Future<ApiResult<DriverStatsModel>> getStats({String period = 'today'}) async {
    return await _apiService.getStats(period: period);
  }
}
