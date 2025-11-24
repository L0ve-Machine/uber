// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restaurantApiServiceHash() =>
    r'df4d90d0e5ad6c03d519aae86a4f29e83a3dce31';

/// RestaurantApiService provider
///
/// Copied from [restaurantApiService].
@ProviderFor(restaurantApiService)
final restaurantApiServiceProvider =
    AutoDisposeProvider<RestaurantApiService>.internal(
  restaurantApiService,
  name: r'restaurantApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantApiServiceRef = AutoDisposeProviderRef<RestaurantApiService>;
String _$restaurantRepositoryHash() =>
    r'e20c6799722dfff9927afbf89443201e255244e3';

/// RestaurantRepository provider
///
/// Copied from [restaurantRepository].
@ProviderFor(restaurantRepository)
final restaurantRepositoryProvider =
    AutoDisposeProvider<RestaurantRepository>.internal(
  restaurantRepository,
  name: r'restaurantRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantRepositoryRef = AutoDisposeProviderRef<RestaurantRepository>;
String _$menuCategoriesHash() => r'f1f847f56549c2de14071048e23da74dd262cc92';

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

/// Get unique menu categories from menu items
///
/// Copied from [menuCategories].
@ProviderFor(menuCategories)
const menuCategoriesProvider = MenuCategoriesFamily();

/// Get unique menu categories from menu items
///
/// Copied from [menuCategories].
class MenuCategoriesFamily extends Family<List<String>> {
  /// Get unique menu categories from menu items
  ///
  /// Copied from [menuCategories].
  const MenuCategoriesFamily();

  /// Get unique menu categories from menu items
  ///
  /// Copied from [menuCategories].
  MenuCategoriesProvider call(
    int restaurantId,
  ) {
    return MenuCategoriesProvider(
      restaurantId,
    );
  }

  @override
  MenuCategoriesProvider getProviderOverride(
    covariant MenuCategoriesProvider provider,
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
  String? get name => r'menuCategoriesProvider';
}

/// Get unique menu categories from menu items
///
/// Copied from [menuCategories].
class MenuCategoriesProvider extends AutoDisposeProvider<List<String>> {
  /// Get unique menu categories from menu items
  ///
  /// Copied from [menuCategories].
  MenuCategoriesProvider(
    int restaurantId,
  ) : this._internal(
          (ref) => menuCategories(
            ref as MenuCategoriesRef,
            restaurantId,
          ),
          from: menuCategoriesProvider,
          name: r'menuCategoriesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$menuCategoriesHash,
          dependencies: MenuCategoriesFamily._dependencies,
          allTransitiveDependencies:
              MenuCategoriesFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
        );

  MenuCategoriesProvider._internal(
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
    List<String> Function(MenuCategoriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MenuCategoriesProvider._internal(
        (ref) => create(ref as MenuCategoriesRef),
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
  AutoDisposeProviderElement<List<String>> createElement() {
    return _MenuCategoriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MenuCategoriesProvider &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MenuCategoriesRef on AutoDisposeProviderRef<List<String>> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;
}

class _MenuCategoriesProviderElement
    extends AutoDisposeProviderElement<List<String>> with MenuCategoriesRef {
  _MenuCategoriesProviderElement(super.provider);

  @override
  int get restaurantId => (origin as MenuCategoriesProvider).restaurantId;
}

String _$restaurantListHash() => r'4b3959f8e5f57af83681fa6ad5a734c1a58bd87d';

abstract class _$RestaurantList
    extends BuildlessAutoDisposeAsyncNotifier<List<RestaurantModel>> {
  late final String? category;
  late final String? search;

  FutureOr<List<RestaurantModel>> build({
    String? category,
    String? search,
  });
}

/// Restaurant list provider with optional filters
///
/// Copied from [RestaurantList].
@ProviderFor(RestaurantList)
const restaurantListProvider = RestaurantListFamily();

/// Restaurant list provider with optional filters
///
/// Copied from [RestaurantList].
class RestaurantListFamily extends Family<AsyncValue<List<RestaurantModel>>> {
  /// Restaurant list provider with optional filters
  ///
  /// Copied from [RestaurantList].
  const RestaurantListFamily();

  /// Restaurant list provider with optional filters
  ///
  /// Copied from [RestaurantList].
  RestaurantListProvider call({
    String? category,
    String? search,
  }) {
    return RestaurantListProvider(
      category: category,
      search: search,
    );
  }

  @override
  RestaurantListProvider getProviderOverride(
    covariant RestaurantListProvider provider,
  ) {
    return call(
      category: provider.category,
      search: provider.search,
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
  String? get name => r'restaurantListProvider';
}

/// Restaurant list provider with optional filters
///
/// Copied from [RestaurantList].
class RestaurantListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantList, List<RestaurantModel>> {
  /// Restaurant list provider with optional filters
  ///
  /// Copied from [RestaurantList].
  RestaurantListProvider({
    String? category,
    String? search,
  }) : this._internal(
          () => RestaurantList()
            ..category = category
            ..search = search,
          from: restaurantListProvider,
          name: r'restaurantListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantListHash,
          dependencies: RestaurantListFamily._dependencies,
          allTransitiveDependencies:
              RestaurantListFamily._allTransitiveDependencies,
          category: category,
          search: search,
        );

  RestaurantListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
    required this.search,
  }) : super.internal();

  final String? category;
  final String? search;

  @override
  FutureOr<List<RestaurantModel>> runNotifierBuild(
    covariant RestaurantList notifier,
  ) {
    return notifier.build(
      category: category,
      search: search,
    );
  }

  @override
  Override overrideWith(RestaurantList Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantListProvider._internal(
        () => create()
          ..category = category
          ..search = search,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
        search: search,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RestaurantList, List<RestaurantModel>>
      createElement() {
    return _RestaurantListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantListProvider &&
        other.category == category &&
        other.search == search;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantListRef
    on AutoDisposeAsyncNotifierProviderRef<List<RestaurantModel>> {
  /// The parameter `category` of this provider.
  String? get category;

  /// The parameter `search` of this provider.
  String? get search;
}

class _RestaurantListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantList,
        List<RestaurantModel>> with RestaurantListRef {
  _RestaurantListProviderElement(super.provider);

  @override
  String? get category => (origin as RestaurantListProvider).category;
  @override
  String? get search => (origin as RestaurantListProvider).search;
}

String _$restaurantDetailHash() => r'0a1b67b6a2b170f0a569f7cebe434d62e8b4039c';

abstract class _$RestaurantDetail
    extends BuildlessAutoDisposeAsyncNotifier<RestaurantModel> {
  late final int restaurantId;

  FutureOr<RestaurantModel> build(
    int restaurantId,
  );
}

/// Restaurant detail provider by ID
///
/// Copied from [RestaurantDetail].
@ProviderFor(RestaurantDetail)
const restaurantDetailProvider = RestaurantDetailFamily();

/// Restaurant detail provider by ID
///
/// Copied from [RestaurantDetail].
class RestaurantDetailFamily extends Family<AsyncValue<RestaurantModel>> {
  /// Restaurant detail provider by ID
  ///
  /// Copied from [RestaurantDetail].
  const RestaurantDetailFamily();

  /// Restaurant detail provider by ID
  ///
  /// Copied from [RestaurantDetail].
  RestaurantDetailProvider call(
    int restaurantId,
  ) {
    return RestaurantDetailProvider(
      restaurantId,
    );
  }

  @override
  RestaurantDetailProvider getProviderOverride(
    covariant RestaurantDetailProvider provider,
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
  String? get name => r'restaurantDetailProvider';
}

/// Restaurant detail provider by ID
///
/// Copied from [RestaurantDetail].
class RestaurantDetailProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantDetail, RestaurantModel> {
  /// Restaurant detail provider by ID
  ///
  /// Copied from [RestaurantDetail].
  RestaurantDetailProvider(
    int restaurantId,
  ) : this._internal(
          () => RestaurantDetail()..restaurantId = restaurantId,
          from: restaurantDetailProvider,
          name: r'restaurantDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantDetailHash,
          dependencies: RestaurantDetailFamily._dependencies,
          allTransitiveDependencies:
              RestaurantDetailFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
        );

  RestaurantDetailProvider._internal(
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
  FutureOr<RestaurantModel> runNotifierBuild(
    covariant RestaurantDetail notifier,
  ) {
    return notifier.build(
      restaurantId,
    );
  }

  @override
  Override overrideWith(RestaurantDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantDetailProvider._internal(
        () => create()..restaurantId = restaurantId,
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
  AutoDisposeAsyncNotifierProviderElement<RestaurantDetail, RestaurantModel>
      createElement() {
    return _RestaurantDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantDetailProvider &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantDetailRef
    on AutoDisposeAsyncNotifierProviderRef<RestaurantModel> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;
}

class _RestaurantDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantDetail,
        RestaurantModel> with RestaurantDetailRef {
  _RestaurantDetailProviderElement(super.provider);

  @override
  int get restaurantId => (origin as RestaurantDetailProvider).restaurantId;
}

String _$restaurantMenuHash() => r'61d695fb542a30cac3ac577b48ec652f1dd40352';

abstract class _$RestaurantMenu
    extends BuildlessAutoDisposeAsyncNotifier<List<MenuItemModel>> {
  late final int restaurantId;
  late final String? category;

  FutureOr<List<MenuItemModel>> build({
    required int restaurantId,
    String? category,
  });
}

/// Restaurant menu provider
///
/// Copied from [RestaurantMenu].
@ProviderFor(RestaurantMenu)
const restaurantMenuProvider = RestaurantMenuFamily();

/// Restaurant menu provider
///
/// Copied from [RestaurantMenu].
class RestaurantMenuFamily extends Family<AsyncValue<List<MenuItemModel>>> {
  /// Restaurant menu provider
  ///
  /// Copied from [RestaurantMenu].
  const RestaurantMenuFamily();

  /// Restaurant menu provider
  ///
  /// Copied from [RestaurantMenu].
  RestaurantMenuProvider call({
    required int restaurantId,
    String? category,
  }) {
    return RestaurantMenuProvider(
      restaurantId: restaurantId,
      category: category,
    );
  }

  @override
  RestaurantMenuProvider getProviderOverride(
    covariant RestaurantMenuProvider provider,
  ) {
    return call(
      restaurantId: provider.restaurantId,
      category: provider.category,
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
  String? get name => r'restaurantMenuProvider';
}

/// Restaurant menu provider
///
/// Copied from [RestaurantMenu].
class RestaurantMenuProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantMenu, List<MenuItemModel>> {
  /// Restaurant menu provider
  ///
  /// Copied from [RestaurantMenu].
  RestaurantMenuProvider({
    required int restaurantId,
    String? category,
  }) : this._internal(
          () => RestaurantMenu()
            ..restaurantId = restaurantId
            ..category = category,
          from: restaurantMenuProvider,
          name: r'restaurantMenuProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantMenuHash,
          dependencies: RestaurantMenuFamily._dependencies,
          allTransitiveDependencies:
              RestaurantMenuFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
          category: category,
        );

  RestaurantMenuProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.restaurantId,
    required this.category,
  }) : super.internal();

  final int restaurantId;
  final String? category;

  @override
  FutureOr<List<MenuItemModel>> runNotifierBuild(
    covariant RestaurantMenu notifier,
  ) {
    return notifier.build(
      restaurantId: restaurantId,
      category: category,
    );
  }

  @override
  Override overrideWith(RestaurantMenu Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantMenuProvider._internal(
        () => create()
          ..restaurantId = restaurantId
          ..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        restaurantId: restaurantId,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<RestaurantMenu, List<MenuItemModel>>
      createElement() {
    return _RestaurantMenuProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantMenuProvider &&
        other.restaurantId == restaurantId &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantMenuRef
    on AutoDisposeAsyncNotifierProviderRef<List<MenuItemModel>> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;

  /// The parameter `category` of this provider.
  String? get category;
}

class _RestaurantMenuProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantMenu,
        List<MenuItemModel>> with RestaurantMenuRef {
  _RestaurantMenuProviderElement(super.provider);

  @override
  int get restaurantId => (origin as RestaurantMenuProvider).restaurantId;
  @override
  String? get category => (origin as RestaurantMenuProvider).category;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
