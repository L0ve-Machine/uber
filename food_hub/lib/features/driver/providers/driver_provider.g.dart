// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$driverApiServiceHash() => r'f9c4edf0ba2bf0a0d3b4d3e7dd9a3c7abc98c4cb';

/// DriverApiService provider
///
/// Copied from [driverApiService].
@ProviderFor(driverApiService)
final driverApiServiceProvider = AutoDisposeProvider<DriverApiService>.internal(
  driverApiService,
  name: r'driverApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DriverApiServiceRef = AutoDisposeProviderRef<DriverApiService>;
String _$driverRepositoryHash() => r'6f945e6e02417800d25a3862d24fe99aeecc3f5d';

/// DriverRepository provider
///
/// Copied from [driverRepository].
@ProviderFor(driverRepository)
final driverRepositoryProvider = AutoDisposeProvider<DriverRepository>.internal(
  driverRepository,
  name: r'driverRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DriverRepositoryRef = AutoDisposeProviderRef<DriverRepository>;
String _$driverOnlineStatusHash() =>
    r'd9de0cd5353f640581851c3050f977cb391ead3c';

/// Driver online status provider
///
/// Copied from [DriverOnlineStatus].
@ProviderFor(DriverOnlineStatus)
final driverOnlineStatusProvider =
    AutoDisposeNotifierProvider<DriverOnlineStatus, bool>.internal(
  DriverOnlineStatus.new,
  name: r'driverOnlineStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverOnlineStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DriverOnlineStatus = AutoDisposeNotifier<bool>;
String _$availableOrdersHash() => r'f19de1ba08731859ae26bdc800ee3911a76a1e6a';

/// Available orders provider (ready for pickup)
///
/// Copied from [AvailableOrders].
@ProviderFor(AvailableOrders)
final availableOrdersProvider = AutoDisposeAsyncNotifierProvider<
    AvailableOrders, List<OrderModel>>.internal(
  AvailableOrders.new,
  name: r'availableOrdersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableOrdersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AvailableOrders = AutoDisposeAsyncNotifier<List<OrderModel>>;
String _$activeDeliveriesHash() => r'3b6316612fd2a1a2e335defc720da62dced5b5f6';

/// Active deliveries provider (picked_up, delivering)
///
/// Copied from [ActiveDeliveries].
@ProviderFor(ActiveDeliveries)
final activeDeliveriesProvider = AutoDisposeAsyncNotifierProvider<
    ActiveDeliveries, List<OrderModel>>.internal(
  ActiveDeliveries.new,
  name: r'activeDeliveriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeDeliveriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveDeliveries = AutoDisposeAsyncNotifier<List<OrderModel>>;
String _$driverOrderHistoryHash() =>
    r'b95e26ab5ab4dc9aaebc4ad516f89795cf2b5b6a';

/// Driver order history provider
///
/// Copied from [DriverOrderHistory].
@ProviderFor(DriverOrderHistory)
final driverOrderHistoryProvider = AutoDisposeAsyncNotifierProvider<
    DriverOrderHistory, List<OrderModel>>.internal(
  DriverOrderHistory.new,
  name: r'driverOrderHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverOrderHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DriverOrderHistory = AutoDisposeAsyncNotifier<List<OrderModel>>;
String _$driverStatsHash() => r'8d4442bf9aa27c39ef9467b3a28fca30164ef8c5';

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

abstract class _$DriverStats
    extends BuildlessAutoDisposeAsyncNotifier<DriverStatsModel> {
  late final String period;

  FutureOr<DriverStatsModel> build({
    String period = 'today',
  });
}

/// Driver statistics provider
///
/// Copied from [DriverStats].
@ProviderFor(DriverStats)
const driverStatsProvider = DriverStatsFamily();

/// Driver statistics provider
///
/// Copied from [DriverStats].
class DriverStatsFamily extends Family<AsyncValue<DriverStatsModel>> {
  /// Driver statistics provider
  ///
  /// Copied from [DriverStats].
  const DriverStatsFamily();

  /// Driver statistics provider
  ///
  /// Copied from [DriverStats].
  DriverStatsProvider call({
    String period = 'today',
  }) {
    return DriverStatsProvider(
      period: period,
    );
  }

  @override
  DriverStatsProvider getProviderOverride(
    covariant DriverStatsProvider provider,
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
  String? get name => r'driverStatsProvider';
}

/// Driver statistics provider
///
/// Copied from [DriverStats].
class DriverStatsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    DriverStats, DriverStatsModel> {
  /// Driver statistics provider
  ///
  /// Copied from [DriverStats].
  DriverStatsProvider({
    String period = 'today',
  }) : this._internal(
          () => DriverStats()..period = period,
          from: driverStatsProvider,
          name: r'driverStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$driverStatsHash,
          dependencies: DriverStatsFamily._dependencies,
          allTransitiveDependencies:
              DriverStatsFamily._allTransitiveDependencies,
          period: period,
        );

  DriverStatsProvider._internal(
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
  FutureOr<DriverStatsModel> runNotifierBuild(
    covariant DriverStats notifier,
  ) {
    return notifier.build(
      period: period,
    );
  }

  @override
  Override overrideWith(DriverStats Function() create) {
    return ProviderOverride(
      origin: this,
      override: DriverStatsProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<DriverStats, DriverStatsModel>
      createElement() {
    return _DriverStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DriverStatsProvider && other.period == period;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, period.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DriverStatsRef on AutoDisposeAsyncNotifierProviderRef<DriverStatsModel> {
  /// The parameter `period` of this provider.
  String get period;
}

class _DriverStatsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DriverStats,
        DriverStatsModel> with DriverStatsRef {
  _DriverStatsProviderElement(super.provider);

  @override
  String get period => (origin as DriverStatsProvider).period;
}

String _$driverLocationHash() => r'f5928f7784264e835da57333e9366c1c9c1f4793';

/// Driver location updater
///
/// Copied from [DriverLocation].
@ProviderFor(DriverLocation)
final driverLocationProvider =
    AutoDisposeAsyncNotifierProvider<DriverLocation, void>.internal(
  DriverLocation.new,
  name: r'driverLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$driverLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DriverLocation = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
