// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderApiServiceHash() => r'67537d7ae7791d2290c3faf219ccd1b4855cb80a';

/// OrderApiService provider
///
/// Copied from [orderApiService].
@ProviderFor(orderApiService)
final orderApiServiceProvider = AutoDisposeProvider<OrderApiService>.internal(
  orderApiService,
  name: r'orderApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OrderApiServiceRef = AutoDisposeProviderRef<OrderApiService>;
String _$orderRepositoryHash() => r'37440bfabd480237b2678ed4e140e6e0e1c23374';

/// OrderRepository provider
///
/// Copied from [orderRepository].
@ProviderFor(orderRepository)
final orderRepositoryProvider = AutoDisposeProvider<OrderRepository>.internal(
  orderRepository,
  name: r'orderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OrderRepositoryRef = AutoDisposeProviderRef<OrderRepository>;
String _$orderHistoryHash() => r'f50b8d785bc76a9310ed441f9000649cb957e797';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$OrderHistory
    extends BuildlessAutoDisposeAsyncNotifier<List<OrderModel>> {
  late final String? status;

  FutureOr<List<OrderModel>> build({
    String? status,
  });
}

/// Order history provider
///
/// Copied from [OrderHistory].
@ProviderFor(OrderHistory)
const orderHistoryProvider = OrderHistoryFamily();

/// Order history provider
///
/// Copied from [OrderHistory].
class OrderHistoryFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Order history provider
  ///
  /// Copied from [OrderHistory].
  const OrderHistoryFamily();

  /// Order history provider
  ///
  /// Copied from [OrderHistory].
  OrderHistoryProvider call({
    String? status,
  }) {
    return OrderHistoryProvider(
      status: status,
    );
  }

  @override
  OrderHistoryProvider getProviderOverride(
    covariant OrderHistoryProvider provider,
  ) {
    return call(
      status: provider.status,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'orderHistoryProvider';
}

/// Order history provider
///
/// Copied from [OrderHistory].
class OrderHistoryProvider extends AutoDisposeAsyncNotifierProviderImpl<
    OrderHistory, List<OrderModel>> {
  /// Order history provider
  ///
  /// Copied from [OrderHistory].
  OrderHistoryProvider({
    String? status,
  }) : this._internal(
          () => OrderHistory()..status = status,
          from: orderHistoryProvider,
          name: r'orderHistoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$orderHistoryHash,
          dependencies: OrderHistoryFamily._dependencies,
          allTransitiveDependencies:
              OrderHistoryFamily._allTransitiveDependencies,
          status: status,
        );

  OrderHistoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  FutureOr<List<OrderModel>> runNotifierBuild(
    covariant OrderHistory notifier,
  ) {
    return notifier.build(
      status: status,
    );
  }

  @override
  Override overrideWith(OrderHistory Function() create) {
    return ProviderOverride(
      origin: this,
      override: OrderHistoryProvider._internal(
        () => create()..status = status,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OrderHistory, List<OrderModel>>
      createElement() {
    return _OrderHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderHistoryProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OrderHistoryRef on AutoDisposeAsyncNotifierProviderRef<List<OrderModel>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _OrderHistoryProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<OrderHistory,
        List<OrderModel>> with OrderHistoryRef {
  _OrderHistoryProviderElement(super.provider);

  @override
  String? get status => (origin as OrderHistoryProvider).status;
}

String _$orderDetailHash() => r'0940be74014357e04ca8a771fbdb1f6d2c51c292';

abstract class _$OrderDetail
    extends BuildlessAutoDisposeAsyncNotifier<OrderModel> {
  late final int orderId;

  FutureOr<OrderModel> build(
    int orderId,
  );
}

/// Order detail provider by ID
///
/// Copied from [OrderDetail].
@ProviderFor(OrderDetail)
const orderDetailProvider = OrderDetailFamily();

/// Order detail provider by ID
///
/// Copied from [OrderDetail].
class OrderDetailFamily extends Family<AsyncValue<OrderModel>> {
  /// Order detail provider by ID
  ///
  /// Copied from [OrderDetail].
  const OrderDetailFamily();

  /// Order detail provider by ID
  ///
  /// Copied from [OrderDetail].
  OrderDetailProvider call(
    int orderId,
  ) {
    return OrderDetailProvider(
      orderId,
    );
  }

  @override
  OrderDetailProvider getProviderOverride(
    covariant OrderDetailProvider provider,
  ) {
    return call(
      provider.orderId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'orderDetailProvider';
}

/// Order detail provider by ID
///
/// Copied from [OrderDetail].
class OrderDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<OrderDetail, OrderModel> {
  /// Order detail provider by ID
  ///
  /// Copied from [OrderDetail].
  OrderDetailProvider(
    int orderId,
  ) : this._internal(
          () => OrderDetail()..orderId = orderId,
          from: orderDetailProvider,
          name: r'orderDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$orderDetailHash,
          dependencies: OrderDetailFamily._dependencies,
          allTransitiveDependencies:
              OrderDetailFamily._allTransitiveDependencies,
          orderId: orderId,
        );

  OrderDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final int orderId;

  @override
  FutureOr<OrderModel> runNotifierBuild(
    covariant OrderDetail notifier,
  ) {
    return notifier.build(
      orderId,
    );
  }

  @override
  Override overrideWith(OrderDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: OrderDetailProvider._internal(
        () => create()..orderId = orderId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OrderDetail, OrderModel>
      createElement() {
    return _OrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OrderDetailRef on AutoDisposeAsyncNotifierProviderRef<OrderModel> {
  /// The parameter `orderId` of this provider.
  int get orderId;
}

class _OrderDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<OrderDetail, OrderModel>
    with OrderDetailRef {
  _OrderDetailProviderElement(super.provider);

  @override
  int get orderId => (origin as OrderDetailProvider).orderId;
}

String _$createOrderHash() => r'ebc4780f78f4123b42746cf7e2137080fd4ec651';

/// Create order action
///
/// Copied from [CreateOrder].
@ProviderFor(CreateOrder)
final createOrderProvider =
    AutoDisposeAsyncNotifierProvider<CreateOrder, OrderModel?>.internal(
  CreateOrder.new,
  name: r'createOrderProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$createOrderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateOrder = AutoDisposeAsyncNotifier<OrderModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
