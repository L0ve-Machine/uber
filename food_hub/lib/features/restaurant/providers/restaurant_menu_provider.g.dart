// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_menu_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$restaurantMenuApiServiceHash() =>
    r'b5d3e49be4ff303ca4cd764165356cf78ef82132';

/// RestaurantMenuApiService provider
///
/// Copied from [restaurantMenuApiService].
@ProviderFor(restaurantMenuApiService)
final restaurantMenuApiServiceProvider =
    AutoDisposeProvider<RestaurantMenuApiService>.internal(
  restaurantMenuApiService,
  name: r'restaurantMenuApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantMenuApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantMenuApiServiceRef
    = AutoDisposeProviderRef<RestaurantMenuApiService>;
String _$restaurantMenuRepositoryHash() =>
    r'7210f72678bd68143133a7f7be549765d2004112';

/// RestaurantMenuRepository provider
///
/// Copied from [restaurantMenuRepository].
@ProviderFor(restaurantMenuRepository)
final restaurantMenuRepositoryProvider =
    AutoDisposeProvider<RestaurantMenuRepository>.internal(
  restaurantMenuRepository,
  name: r'restaurantMenuRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$restaurantMenuRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RestaurantMenuRepositoryRef
    = AutoDisposeProviderRef<RestaurantMenuRepository>;
String _$restaurantMenuHash() => r'c38679d57fd019a076cd077d6af8686bcefd9b3e';

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

abstract class _$RestaurantMenu
    extends BuildlessAutoDisposeAsyncNotifier<List<MenuItemModel>> {
  late final String? category;

  FutureOr<List<MenuItemModel>> build({
    String? category,
  });
}

/// Restaurant menu list provider
///
/// Copied from [RestaurantMenu].
@ProviderFor(RestaurantMenu)
const restaurantMenuProvider = RestaurantMenuFamily();

/// Restaurant menu list provider
///
/// Copied from [RestaurantMenu].
class RestaurantMenuFamily extends Family<AsyncValue<List<MenuItemModel>>> {
  /// Restaurant menu list provider
  ///
  /// Copied from [RestaurantMenu].
  const RestaurantMenuFamily();

  /// Restaurant menu list provider
  ///
  /// Copied from [RestaurantMenu].
  RestaurantMenuProvider call({
    String? category,
  }) {
    return RestaurantMenuProvider(
      category: category,
    );
  }

  @override
  RestaurantMenuProvider getProviderOverride(
    covariant RestaurantMenuProvider provider,
  ) {
    return call(
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

/// Restaurant menu list provider
///
/// Copied from [RestaurantMenu].
class RestaurantMenuProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantMenu, List<MenuItemModel>> {
  /// Restaurant menu list provider
  ///
  /// Copied from [RestaurantMenu].
  RestaurantMenuProvider({
    String? category,
  }) : this._internal(
          () => RestaurantMenu()..category = category,
          from: restaurantMenuProvider,
          name: r'restaurantMenuProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantMenuHash,
          dependencies: RestaurantMenuFamily._dependencies,
          allTransitiveDependencies:
              RestaurantMenuFamily._allTransitiveDependencies,
          category: category,
        );

  RestaurantMenuProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
  }) : super.internal();

  final String? category;

  @override
  FutureOr<List<MenuItemModel>> runNotifierBuild(
    covariant RestaurantMenu notifier,
  ) {
    return notifier.build(
      category: category,
    );
  }

  @override
  Override overrideWith(RestaurantMenu Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantMenuProvider._internal(
        () => create()..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
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
    return other is RestaurantMenuProvider && other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantMenuRef
    on AutoDisposeAsyncNotifierProviderRef<List<MenuItemModel>> {
  /// The parameter `category` of this provider.
  String? get category;
}

class _RestaurantMenuProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantMenu,
        List<MenuItemModel>> with RestaurantMenuRef {
  _RestaurantMenuProviderElement(super.provider);

  @override
  String? get category => (origin as RestaurantMenuProvider).category;
}

String _$addMenuItemHash() => r'9d695b7c563e17593b64de909d5097daf4d95552';

/// Add menu item action provider
///
/// Copied from [AddMenuItem].
@ProviderFor(AddMenuItem)
final addMenuItemProvider =
    AutoDisposeAsyncNotifierProvider<AddMenuItem, MenuItemModel?>.internal(
  AddMenuItem.new,
  name: r'addMenuItemProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$addMenuItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddMenuItem = AutoDisposeAsyncNotifier<MenuItemModel?>;
String _$updateMenuItemHash() => r'13e001e7b6051a3d9b9fe959f8ea53e5bfd2d574';

/// Update menu item action provider
///
/// Copied from [UpdateMenuItem].
@ProviderFor(UpdateMenuItem)
final updateMenuItemProvider =
    AutoDisposeAsyncNotifierProvider<UpdateMenuItem, MenuItemModel?>.internal(
  UpdateMenuItem.new,
  name: r'updateMenuItemProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateMenuItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UpdateMenuItem = AutoDisposeAsyncNotifier<MenuItemModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
