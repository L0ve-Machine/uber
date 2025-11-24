import '../../../../core/network/api_result.dart';
import '../../../../shared/models/order_model.dart';
import '../services/order_api_service.dart';
import '../../models/cart_item.dart';

/// Order Repository
class OrderRepository {
  final OrderApiService _apiService;

  OrderRepository({required OrderApiService apiService})
      : _apiService = apiService;

  /// Create order from cart items
  Future<ApiResult<OrderModel>> createOrder({
    required int restaurantId,
    required int deliveryAddressId,
    required List<CartItem> cartItems,
    required String paymentMethod,
    String? specialInstructions,
    DateTime? scheduledAt,
  }) async {
    // Convert cart items to API format
    final items = cartItems.map((cartItem) {
      return {
        'menu_item_id': cartItem.menuItem.id,
        'quantity': cartItem.quantity,
        'selected_options': cartItem.selectedOptions.map((opt) {
          return {
            'group': opt.group,
            'name': opt.name,
            'price': opt.price,
          };
        }).toList(),
        if (cartItem.specialRequest != null)
          'special_request': cartItem.specialRequest,
      };
    }).toList();

    return await _apiService.createOrder(
      restaurantId: restaurantId,
      deliveryAddressId: deliveryAddressId,
      items: items,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
      scheduledAt: scheduledAt,
    );
  }

  /// Get customer's orders
  Future<ApiResult<List<OrderModel>>> getOrders({String? status}) async {
    return await _apiService.getOrders(status: status);
  }

  /// Get order by ID
  Future<ApiResult<OrderModel>> getOrderById(int id) async {
    return await _apiService.getOrderById(id);
  }

  /// Cancel order
  Future<ApiResult<OrderModel>> cancelOrder(int id) async {
    return await _apiService.cancelOrder(id);
  }
}
