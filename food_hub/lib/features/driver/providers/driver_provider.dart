import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/driver_model.dart';
import '../data/repositories/driver_repository.dart';
import '../data/services/driver_api_service.dart';
import '../models/driver_stats_model.dart';
import 'driver_profile_provider.dart';

part 'driver_provider.g.dart';

/// DriverApiService provider
@riverpod
DriverApiService driverApiService(DriverApiServiceRef ref) {
  return DriverApiService(ref.watch(dioProvider));
}

/// DriverRepository provider
@riverpod
DriverRepository driverRepository(DriverRepositoryRef ref) {
  return DriverRepository(
    apiService: ref.watch(driverApiServiceProvider),
  );
}

/// Driver online status provider
@riverpod
class DriverOnlineStatus extends _$DriverOnlineStatus {
  @override
  bool build() {
    // Read initial status from driver profile
    final driverAsync = ref.watch(driverProfileProvider);
    return driverAsync.valueOrNull?.isOnline ?? false;
  }

  Future<Map<String, dynamic>> toggleOnline(bool isOnline) async {
    // Temporarily disabled all Stripe checks for testing
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.toggleOnlineStatus(isOnline);

    return result.when(
      success: (newStatus) {
        state = newStatus;
        if (newStatus) {
          // Refresh available orders when coming online
          ref.invalidate(availableOrdersProvider);
        }
        return {'success': true, 'message': null};
      },
      failure: (error) {
        // サーバーからのエラーメッセージを返す
        return {'success': false, 'message': error};
      },
    );
  }
}

/// Available orders provider (ready for pickup)
@riverpod
class AvailableOrders extends _$AvailableOrders {
  @override
  Future<List<OrderModel>> build() async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.getAvailableOrders();

    return result.when(
      success: (orders) => orders,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<bool> acceptDelivery(int orderId) async {
    // Temporarily disabled Stripe check for testing
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.acceptDelivery(orderId);

    return result.when(
      success: (order) {
        // Remove from available orders
        state.whenData((orders) {
          final updatedOrders = orders.where((o) => o.id != orderId).toList();
          state = AsyncValue.data(updatedOrders);
        });
        // Refresh active deliveries
        ref.invalidate(activeDeliveriesProvider);
        return true;
      },
      failure: (error) => false,
    );
  }
}

/// Active deliveries provider (picked_up, delivering)
@riverpod
class ActiveDeliveries extends _$ActiveDeliveries {
  @override
  Future<List<OrderModel>> build() async {
    final repository = ref.read(driverRepositoryProvider);

    // Get orders in active delivery states
    final pickedUpResult = await repository.getDriverOrders(status: 'picked_up');
    final deliveringResult = await repository.getDriverOrders(status: 'delivering');

    final List<OrderModel> activeOrders = [];

    pickedUpResult.when(
      success: (orders) => activeOrders.addAll(orders),
      failure: (_) {},
    );

    deliveringResult.when(
      success: (orders) => activeOrders.addAll(orders),
      failure: (_) {},
    );

    return activeOrders;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<bool> startDelivering(int orderId) async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.startDelivering(orderId);

    return result.when(
      success: (order) {
        _updateOrderInList(order);
        return true;
      },
      failure: (error) => false,
    );
  }

  Future<bool> completeDelivery(int orderId) async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.completeDelivery(orderId);

    return result.when(
      success: (order) {
        // Remove from active deliveries
        state.whenData((orders) {
          final updatedOrders = orders.where((o) => o.id != orderId).toList();
          state = AsyncValue.data(updatedOrders);
        });
        // Refresh stats
        ref.invalidate(driverStatsProvider());
        return true;
      },
      failure: (error) => false,
    );
  }

  Future<bool> verifyPickupPin(int orderId, String pin) async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.verifyPickupPin(orderId, pin);

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

/// Driver order history provider
@riverpod
class DriverOrderHistory extends _$DriverOrderHistory {
  @override
  Future<List<OrderModel>> build() async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.getDriverOrders(status: 'delivered');

    return result.when(
      success: (orders) => orders,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Driver statistics provider
@riverpod
class DriverStats extends _$DriverStats {
  String _currentPeriod = 'today';

  @override
  Future<DriverStatsModel> build({String period = 'today'}) async {
    _currentPeriod = period;

    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.getStats(period: period);

    return result.when(
      success: (stats) => stats,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(period: _currentPeriod));
  }

  Future<void> changePeriod(String period) async {
    _currentPeriod = period;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(period: period));
  }
}

/// Driver location updater
@riverpod
class DriverLocation extends _$DriverLocation {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<bool> updateLocation(double latitude, double longitude) async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.updateLocation(latitude, longitude);

    return result.when(
      success: (_) => true,
      failure: (_) => false,
    );
  }
}
