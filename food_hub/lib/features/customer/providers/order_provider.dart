import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/order_model.dart';
import '../data/repositories/order_repository.dart';
import '../data/services/order_api_service.dart';
import 'cart_provider.dart';

part 'order_provider.g.dart';

/// OrderApiService provider
@riverpod
OrderApiService orderApiService(OrderApiServiceRef ref) {
  return OrderApiService(ref.watch(dioProvider));
}

/// OrderRepository provider
@riverpod
OrderRepository orderRepository(OrderRepositoryRef ref) {
  return OrderRepository(
    apiService: ref.watch(orderApiServiceProvider),
  );
}

/// Order history provider
@riverpod
class OrderHistory extends _$OrderHistory {
  String? _currentStatus;

  @override
  Future<List<OrderModel>> build({String? status}) async {
    _currentStatus = status;

    final repository = ref.read(orderRepositoryProvider);
    final result = await repository.getOrders(status: status);

    return result.when(
      success: (orders) => orders,
      failure: (error) => throw error,
    );
  }

  /// Refresh order history
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(status: _currentStatus));
  }

  /// Filter by status
  Future<void> filterByStatus(String? status) async {
    _currentStatus = status;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(status: status));
  }
}

/// Order detail provider by ID
@riverpod
class OrderDetail extends _$OrderDetail {
  @override
  Future<OrderModel> build(int orderId) async {
    final repository = ref.read(orderRepositoryProvider);
    final result = await repository.getOrderById(orderId);

    return result.when(
      success: (order) => order,
      failure: (error) => throw error,
    );
  }

  /// Refresh order detail
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(orderId));
  }

  /// Cancel order
  Future<bool> cancelOrder() async {
    final repository = ref.read(orderRepositoryProvider);
    final result = await repository.cancelOrder(orderId);

    return result.when(
      success: (order) {
        // Update state with cancelled order
        state = AsyncValue.data(order);
        // Invalidate order history to refresh list
        ref.invalidate(orderHistoryProvider());
        return true;
      },
      failure: (error) {
        // Keep current state on error
        return false;
      },
    );
  }
}

/// Create order action
@riverpod
class CreateOrder extends _$CreateOrder {
  @override
  FutureOr<OrderModel?> build() {
    return null;
  }

  /// Create order from current cart
  Future<ApiResult<OrderModel>> placeOrder({
    required int restaurantId,
    required int deliveryAddressId,
    required String paymentMethod,
    String? specialInstructions,
  }) async {
    state = const AsyncValue.loading();

    final cartItems = ref.read(cartProvider);
    final repository = ref.read(orderRepositoryProvider);

    final result = await repository.createOrder(
      restaurantId: restaurantId,
      deliveryAddressId: deliveryAddressId,
      cartItems: cartItems,
      paymentMethod: paymentMethod,
      specialInstructions: specialInstructions,
    );

    state = result.when(
      success: (order) {
        // Clear cart on successful order
        ref.read(cartProvider.notifier).clear();
        // Invalidate order history to refresh
        ref.invalidate(orderHistoryProvider());
        return AsyncValue.data(order);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }
}
