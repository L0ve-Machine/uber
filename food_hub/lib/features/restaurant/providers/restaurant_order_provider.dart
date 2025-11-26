import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/order_model.dart';
import '../data/repositories/restaurant_order_repository.dart';
import '../data/services/restaurant_order_api_service.dart';
import '../models/restaurant_stats_model.dart';

part 'restaurant_order_provider.g.dart';

/// RestaurantOrderApiService provider
@riverpod
RestaurantOrderApiService restaurantOrderApiService(RestaurantOrderApiServiceRef ref) {
  return RestaurantOrderApiService(ref.watch(dioProvider));
}

/// RestaurantOrderRepository provider
@riverpod
RestaurantOrderRepository restaurantOrderRepository(RestaurantOrderRepositoryRef ref) {
  return RestaurantOrderRepository(
    apiService: ref.watch(restaurantOrderApiServiceProvider),
  );
}

/// Restaurant orders list provider
@riverpod
class RestaurantOrders extends _$RestaurantOrders {
  String? _currentStatus;

  @override
  Future<List<OrderModel>> build({String? status}) async {
    _currentStatus = status;

    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.getOrders(status: status);

    return result.when(
      success: (orders) => orders,
      failure: (error) => throw error,
    );
  }

  /// Refresh orders
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

  /// Accept order
  Future<bool> acceptOrder(int orderId) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.acceptOrder(orderId);

    return result.when(
      success: (order) {
        // Update the order in the list
        _updateOrderInList(order);
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Reject order
  Future<bool> rejectOrder(int orderId, {String? reason}) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.rejectOrder(orderId, reason: reason);

    return result.when(
      success: (order) {
        // Update the order in the list
        _updateOrderInList(order);
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Start preparing order
  Future<bool> startPreparing(int orderId) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.startPreparing(orderId);

    return result.when(
      success: (order) {
        _updateOrderInList(order);
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Mark order as ready
  Future<bool> markReady(int orderId) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.markReady(orderId);

    return result.when(
      success: (order) {
        _updateOrderInList(order);
        return true;
      },
      failure: (error) => false,
    );
  }

  void _updateOrderInList(OrderModel updatedOrder) {
    state.whenData((orders) {
      final updatedOrders = orders.map((order) {
        return order.id == updatedOrder.id ? updatedOrder : order;
      }).toList();
      state = AsyncValue.data(updatedOrders);
    });
  }
}

/// Restaurant order detail provider
@riverpod
class RestaurantOrderDetail extends _$RestaurantOrderDetail {
  @override
  Future<OrderModel> build(int orderId) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
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

  /// Accept order
  Future<bool> accept() async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.acceptOrder(orderId);

    return result.when(
      success: (order) {
        state = AsyncValue.data(order);
        ref.invalidate(restaurantOrdersProvider());
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Reject order
  Future<bool> reject({String? reason}) async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.rejectOrder(orderId, reason: reason);

    return result.when(
      success: (order) {
        state = AsyncValue.data(order);
        ref.invalidate(restaurantOrdersProvider());
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Start preparing
  Future<bool> startPreparing() async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.startPreparing(orderId);

    return result.when(
      success: (order) {
        state = AsyncValue.data(order);
        ref.invalidate(restaurantOrdersProvider());
        return true;
      },
      failure: (error) => false,
    );
  }

  /// Mark as ready
  Future<bool> markReady() async {
    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.markReady(orderId);

    return result.when(
      success: (order) {
        state = AsyncValue.data(order);
        ref.invalidate(restaurantOrdersProvider());
        return true;
      },
      failure: (error) => false,
    );
  }
}

/// Restaurant statistics provider
@riverpod
class RestaurantStats extends _$RestaurantStats {
  String _currentPeriod = 'today';

  @override
  Future<RestaurantStatsModel> build({String period = 'today'}) async {
    _currentPeriod = period;

    final repository = ref.read(restaurantOrderRepositoryProvider);
    final result = await repository.getStats(period: period);

    return result.when(
      success: (stats) => stats,
      failure: (error) => throw error,
    );
  }

  /// Refresh stats
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(period: _currentPeriod));
  }

  /// Change period
  Future<void> changePeriod(String period) async {
    _currentPeriod = period;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(period: period));
  }
}
