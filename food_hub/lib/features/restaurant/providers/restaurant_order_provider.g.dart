// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_order_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restaurantOrderApiServiceHash() =>
    r'4a7d630f713d7262f09052b00eb4fc4b33b52580';

/// RestaurantOrderApiService provider
///
/// Copied from [restaurantOrderApiService].
@ProviderFor(restaurantOrderApiService)
final restaurantOrderApiServiceProvider =
    AutoDisposeProvider<RestaurantOrderApiService>.internal(
  restaurantOrderApiService,
  name: r'restaurantOrderApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantOrderApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantOrderApiServiceRef
    = AutoDisposeProviderRef<RestaurantOrderApiService>;
String _$restaurantOrderRepositoryHash() =>
    r'e284a5970c953e1ce152a4d171291fb78a0b528c';

/// RestaurantOrderRepository provider
///
/// Copied from [restaurantOrderRepository].
@ProviderFor(restaurantOrderRepository)
final restaurantOrderRepositoryProvider =
    AutoDisposeProvider<RestaurantOrderRepository>.internal(
  restaurantOrderRepository,
  name: r'restaurantOrderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantOrderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantOrderRepositoryRef
    = AutoDisposeProviderRef<RestaurantOrderRepository>;
String _$restaurantOrdersHash() => r'fc605b9098cf80c51d77b184a1f19fc249b8da67';

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

abstract class _$RestaurantOrders
    extends BuildlessAutoDisposeAsyncNotifier<List<OrderModel>> {
  late final String? status;

  FutureOr<List<OrderModel>> build({
    String? status,
  });
}

/// Restaurant orders list provider
///
/// Copied from [RestaurantOrders].
@ProviderFor(RestaurantOrders)
const restaurantOrdersProvider = RestaurantOrdersFamily();

/// Restaurant orders list provider
///
/// Copied from [RestaurantOrders].
class RestaurantOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// Restaurant orders list provider
  ///
  /// Copied from [RestaurantOrders].
  const RestaurantOrdersFamily();

  /// Restaurant orders list provider
  ///
  /// Copied from [RestaurantOrders].
  RestaurantOrdersProvider call({
    String? status,
  }) {
    return RestaurantOrdersProvider(
      status: status,
    );
  }

  @override
  RestaurantOrdersProvider getProviderOverride(
    covariant RestaurantOrdersProvider provider,
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
  String? get name => r'restaurantOrdersProvider';
}

/// Restaurant orders list provider
///
/// Copied from [RestaurantOrders].
class RestaurantOrdersProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantOrders, List<OrderModel>> {
  /// Restaurant orders list provider
  ///
  /// Copied from [RestaurantOrders].
  RestaurantOrdersProvider({
    String? status,
  }) : this._internal(
          () => RestaurantOrders()..status = status,
          from: restaurantOrdersProvider,
          name: r'restaurantOrdersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantOrdersHash,
          dependencies: RestaurantOrdersFamily._dependencies,
          allTransitiveDependencies:
              RestaurantOrdersFamily._allTransitiveDependencies,
          status: status,
        );

  RestaurantOrdersProvider._internal(
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
    covariant RestaurantOrders notifier,
  ) {
    return notifier.build(
      status: status,
    );
  }

  @override
  Override overrideWith(RestaurantOrders Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantOrdersProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<RestaurantOrders, List<OrderModel>>
      createElement() {
    return _RestaurantOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantOrdersProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantOrdersRef
    on AutoDisposeAsyncNotifierProviderRef<List<OrderModel>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _RestaurantOrdersProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantOrders,
        List<OrderModel>> with RestaurantOrdersRef {
  _RestaurantOrdersProviderElement(super.provider);

  @override
  String? get status => (origin as RestaurantOrdersProvider).status;
}

String _$restaurantOrderDetailHash() =>
    r'3037a8a70eb7cd7dd16fe0ff763127de0c3a1a20';

abstract class _$RestaurantOrderDetail
    extends BuildlessAutoDisposeAsyncNotifier<OrderModel> {
  late final int orderId;

  FutureOr<OrderModel> build(
    int orderId,
  );
}

/// Restaurant order detail provider
///
/// Copied from [RestaurantOrderDetail].
@ProviderFor(RestaurantOrderDetail)
const restaurantOrderDetailProvider = RestaurantOrderDetailFamily();

/// Restaurant order detail provider
///
/// Copied from [RestaurantOrderDetail].
class RestaurantOrderDetailFamily extends Family<AsyncValue<OrderModel>> {
  /// Restaurant order detail provider
  ///
  /// Copied from [RestaurantOrderDetail].
  const RestaurantOrderDetailFamily();

  /// Restaurant order detail provider
  ///
  /// Copied from [RestaurantOrderDetail].
  RestaurantOrderDetailProvider call(
    int orderId,
  ) {
    return RestaurantOrderDetailProvider(
      orderId,
    );
  }

  @override
  RestaurantOrderDetailProvider getProviderOverride(
    covariant RestaurantOrderDetailProvider provider,
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
  String? get name => r'restaurantOrderDetailProvider';
}

/// Restaurant order detail provider
///
/// Copied from [RestaurantOrderDetail].
class RestaurantOrderDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<RestaurantOrderDetail,
        OrderModel> {
  /// Restaurant order detail provider
  ///
  /// Copied from [RestaurantOrderDetail].
  RestaurantOrderDetailProvider(
    int orderId,
  ) : this._internal(
          () => RestaurantOrderDetail()..orderId = orderId,
          from: restaurantOrderDetailProvider,
          name: r'restaurantOrderDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantOrderDetailHash,
          dependencies: RestaurantOrderDetailFamily._dependencies,
          allTransitiveDependencies:
              RestaurantOrderDetailFamily._allTransitiveDependencies,
          orderId: orderId,
        );

  RestaurantOrderDetailProvider._internal(
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
    covariant RestaurantOrderDetail notifier,
  ) {
    return notifier.build(
      orderId,
    );
  }

  @override
  Override overrideWith(RestaurantOrderDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantOrderDetailProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<RestaurantOrderDetail, OrderModel>
      createElement() {
    return _RestaurantOrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantOrderDetailProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantOrderDetailRef
    on AutoDisposeAsyncNotifierProviderRef<OrderModel> {
  /// The parameter `orderId` of this provider.
  int get orderId;
}

class _RestaurantOrderDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantOrderDetail,
        OrderModel> with RestaurantOrderDetailRef {
  _RestaurantOrderDetailProviderElement(super.provider);

  @override
  int get orderId => (origin as RestaurantOrderDetailProvider).orderId;
}

String _$restaurantStatsHash() => r'2111f329dbbb3aaa4ab43228e159b7ef8cf5a6c8';

abstract class _$RestaurantStats
    extends BuildlessAutoDisposeAsyncNotifier<RestaurantStatsModel> {
  late final String period;

  FutureOr<RestaurantStatsModel> build({
    String period = 'today',
  });
}

/// Restaurant statistics provider
///
/// Copied from [RestaurantStats].
@ProviderFor(RestaurantStats)
const restaurantStatsProvider = RestaurantStatsFamily();

/// Restaurant statistics provider
///
/// Copied from [RestaurantStats].
class RestaurantStatsFamily extends Family<AsyncValue<RestaurantStatsModel>> {
  /// Restaurant statistics provider
  ///
  /// Copied from [RestaurantStats].
  const RestaurantStatsFamily();

  /// Restaurant statistics provider
  ///
  /// Copied from [RestaurantStats].
  RestaurantStatsProvider call({
    String period = 'today',
  }) {
    return RestaurantStatsProvider(
      period: period,
    );
  }

  @override
  RestaurantStatsProvider getProviderOverride(
    covariant RestaurantStatsProvider provider,
  ) {
    return call(
      period: provider.period,
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
  String? get name => r'restaurantStatsProvider';
}

/// Restaurant statistics provider
///
/// Copied from [RestaurantStats].
class RestaurantStatsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantStats, RestaurantStatsModel> {
  /// Restaurant statistics provider
  ///
  /// Copied from [RestaurantStats].
  RestaurantStatsProvider({
    String period = 'today',
  }) : this._internal(
          () => RestaurantStats()..period = period,
          from: restaurantStatsProvider,
          name: r'restaurantStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantStatsHash,
          dependencies: RestaurantStatsFamily._dependencies,
          allTransitiveDependencies:
              RestaurantStatsFamily._allTransitiveDependencies,
          period: period,
        );

  RestaurantStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.period,
  }) : super.internal();

  final String period;

  @override
  FutureOr<RestaurantStatsModel> runNotifierBuild(
    covariant RestaurantStats notifier,
  ) {
    return notifier.build(
      period: period,
    );
  }

  @override
  Override overrideWith(RestaurantStats Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantStatsProvider._internal(
        () => create()..period = period,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        period: period,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RestaurantStats, RestaurantStatsModel>
      createElement() {
    return _RestaurantStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantStatsProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantStatsRef
    on AutoDisposeAsyncNotifierProviderRef<RestaurantStatsModel> {
  /// The parameter `period` of this provider.
  String get period;
}

class _RestaurantStatsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantStats,
        RestaurantStatsModel> with RestaurantStatsRef {
  _RestaurantStatsProviderElement(super.provider);

  @override
  String get period => (origin as RestaurantStatsProvider).period;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
