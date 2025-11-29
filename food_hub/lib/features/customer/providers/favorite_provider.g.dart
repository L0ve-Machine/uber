// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteApiServiceHash() =>
    r'599ce194e0ae51cc1aa9d5601cf407817400cc5b';

/// FavoriteApiService provider
///
/// Copied from [favoriteApiService].
@ProviderFor(favoriteApiService)
final favoriteApiServiceProvider =
    AutoDisposeProvider<FavoriteApiService>.internal(
  favoriteApiService,
  name: r'favoriteApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FavoriteApiServiceRef = AutoDisposeProviderRef<FavoriteApiService>;
String _$favoriteRepositoryHash() =>
    r'2cc7d68f7122f3c795b6c4faf0839079f4af5520';

/// FavoriteRepository provider
///
/// Copied from [favoriteRepository].
@ProviderFor(favoriteRepository)
final favoriteRepositoryProvider =
    AutoDisposeProvider<FavoriteRepository>.internal(
  favoriteRepository,
  name: r'favoriteRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FavoriteRepositoryRef = AutoDisposeProviderRef<FavoriteRepository>;
String _$favoriteByRestaurantIdHash() =>
    r'9445cd1eb182842720afe0bfc39ef185dbab7faa';

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

/// Get favorite by restaurant ID
///
/// Copied from [favoriteByRestaurantId].
@ProviderFor(favoriteByRestaurantId)
const favoriteByRestaurantIdProvider = FavoriteByRestaurantIdFamily();

/// Get favorite by restaurant ID
///
/// Copied from [favoriteByRestaurantId].
class FavoriteByRestaurantIdFamily extends Family<FavoriteModel?> {
  /// Get favorite by restaurant ID
  ///
  /// Copied from [favoriteByRestaurantId].
  const FavoriteByRestaurantIdFamily();

  /// Get favorite by restaurant ID
  ///
  /// Copied from [favoriteByRestaurantId].
  FavoriteByRestaurantIdProvider call(
    int restaurantId,
  ) {
    return FavoriteByRestaurantIdProvider(
      restaurantId,
    );
  }

  @override
  FavoriteByRestaurantIdProvider getProviderOverride(
    covariant FavoriteByRestaurantIdProvider provider,
  ) {
    return call(
      provider.restaurantId,
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
  String? get name => r'favoriteByRestaurantIdProvider';
}

/// Get favorite by restaurant ID
///
/// Copied from [favoriteByRestaurantId].
class FavoriteByRestaurantIdProvider
    extends AutoDisposeProvider<FavoriteModel?> {
  /// Get favorite by restaurant ID
  ///
  /// Copied from [favoriteByRestaurantId].
  FavoriteByRestaurantIdProvider(
    int restaurantId,
  ) : this._internal(
          (ref) => favoriteByRestaurantId(
            ref as FavoriteByRestaurantIdRef,
            restaurantId,
          ),
          from: favoriteByRestaurantIdProvider,
          name: r'favoriteByRestaurantIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$favoriteByRestaurantIdHash,
          dependencies: FavoriteByRestaurantIdFamily._dependencies,
          allTransitiveDependencies:
              FavoriteByRestaurantIdFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
        );

  FavoriteByRestaurantIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.restaurantId,
  }) : super.internal();

  final int restaurantId;

  @override
  Override overrideWith(
    FavoriteModel? Function(FavoriteByRestaurantIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FavoriteByRestaurantIdProvider._internal(
        (ref) => create(ref as FavoriteByRestaurantIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        restaurantId: restaurantId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<FavoriteModel?> createElement() {
    return _FavoriteByRestaurantIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteByRestaurantIdProvider &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FavoriteByRestaurantIdRef on AutoDisposeProviderRef<FavoriteModel?> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;
}

class _FavoriteByRestaurantIdProviderElement
    extends AutoDisposeProviderElement<FavoriteModel?>
    with FavoriteByRestaurantIdRef {
  _FavoriteByRestaurantIdProviderElement(super.provider);

  @override
  int get restaurantId =>
      (origin as FavoriteByRestaurantIdProvider).restaurantId;
}

String _$isFavoritedHash() => r'b0a40d88606dcabad795e7712ca741a24f811285';

/// Check if restaurant is favorited
///
/// Copied from [isFavorited].
@ProviderFor(isFavorited)
const isFavoritedProvider = IsFavoritedFamily();

/// Check if restaurant is favorited
///
/// Copied from [isFavorited].
class IsFavoritedFamily extends Family<bool> {
  /// Check if restaurant is favorited
  ///
  /// Copied from [isFavorited].
  const IsFavoritedFamily();

  /// Check if restaurant is favorited
  ///
  /// Copied from [isFavorited].
  IsFavoritedProvider call(
    int restaurantId,
  ) {
    return IsFavoritedProvider(
      restaurantId,
    );
  }

  @override
  IsFavoritedProvider getProviderOverride(
    covariant IsFavoritedProvider provider,
  ) {
    return call(
      provider.restaurantId,
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
  String? get name => r'isFavoritedProvider';
}

/// Check if restaurant is favorited
///
/// Copied from [isFavorited].
class IsFavoritedProvider extends AutoDisposeProvider<bool> {
  /// Check if restaurant is favorited
  ///
  /// Copied from [isFavorited].
  IsFavoritedProvider(
    int restaurantId,
  ) : this._internal(
          (ref) => isFavorited(
            ref as IsFavoritedRef,
            restaurantId,
          ),
          from: isFavoritedProvider,
          name: r'isFavoritedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isFavoritedHash,
          dependencies: IsFavoritedFamily._dependencies,
          allTransitiveDependencies:
              IsFavoritedFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
        );

  IsFavoritedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.restaurantId,
  }) : super.internal();

  final int restaurantId;

  @override
  Override overrideWith(
    bool Function(IsFavoritedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsFavoritedProvider._internal(
        (ref) => create(ref as IsFavoritedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        restaurantId: restaurantId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsFavoritedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoritedProvider && other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IsFavoritedRef on AutoDisposeProviderRef<bool> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;
}

class _IsFavoritedProviderElement extends AutoDisposeProviderElement<bool>
    with IsFavoritedRef {
  _IsFavoritedProviderElement(super.provider);

  @override
  int get restaurantId => (origin as IsFavoritedProvider).restaurantId;
}

String _$favoritesCountHash() => r'004c50b4dede60feba413c9a431f5f7dcd26f98d';

/// Get total favorites count
///
/// Copied from [favoritesCount].
@ProviderFor(favoritesCount)
final favoritesCountProvider = AutoDisposeProvider<int>.internal(
  favoritesCount,
  name: r'favoritesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoritesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FavoritesCountRef = AutoDisposeProviderRef<int>;
String _$favoriteListHash() => r'e54bfac7356386345d5ebb818687e307e34720aa';

/// Favorite list provider
///
/// Copied from [FavoriteList].
@ProviderFor(FavoriteList)
final favoriteListProvider = AutoDisposeAsyncNotifierProvider<FavoriteList,
    List<FavoriteModel>>.internal(
  FavoriteList.new,
  name: r'favoriteListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$favoriteListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoriteList = AutoDisposeAsyncNotifier<List<FavoriteModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
