// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewApiServiceHash() => r'62bfc2d3247f6d1c9cbdc2d039cee2c8939283c1';

/// ReviewApiService provider
///
/// Copied from [reviewApiService].
@ProviderFor(reviewApiService)
final reviewApiServiceProvider = AutoDisposeProvider<ReviewApiService>.internal(
  reviewApiService,
  name: r'reviewApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReviewApiServiceRef = AutoDisposeProviderRef<ReviewApiService>;
String _$reviewRepositoryHash() => r'203aaafb50b2512caf628908f2038f088533a3fc';

/// ReviewRepository provider
///
/// Copied from [reviewRepository].
@ProviderFor(reviewRepository)
final reviewRepositoryProvider = AutoDisposeProvider<ReviewRepository>.internal(
  reviewRepository,
  name: r'reviewRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReviewRepositoryRef = AutoDisposeProviderRef<ReviewRepository>;
String _$canReviewHash() => r'1be5b9f6418198c80c9b778a03b2253bb44dfefb';

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

/// Can review check provider
///
/// Copied from [canReview].
@ProviderFor(canReview)
const canReviewProvider = CanReviewFamily();

/// Can review check provider
///
/// Copied from [canReview].
class CanReviewFamily extends Family<AsyncValue<CanReviewResponse>> {
  /// Can review check provider
  ///
  /// Copied from [canReview].
  const CanReviewFamily();

  /// Can review check provider
  ///
  /// Copied from [canReview].
  CanReviewProvider call(
    int orderId,
  ) {
    return CanReviewProvider(
      orderId,
    );
  }

  @override
  CanReviewProvider getProviderOverride(
    covariant CanReviewProvider provider,
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
  String? get name => r'canReviewProvider';
}

/// Can review check provider
///
/// Copied from [canReview].
class CanReviewProvider extends AutoDisposeFutureProvider<CanReviewResponse> {
  /// Can review check provider
  ///
  /// Copied from [canReview].
  CanReviewProvider(
    int orderId,
  ) : this._internal(
          (ref) => canReview(
            ref as CanReviewRef,
            orderId,
          ),
          from: canReviewProvider,
          name: r'canReviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$canReviewHash,
          dependencies: CanReviewFamily._dependencies,
          allTransitiveDependencies: CanReviewFamily._allTransitiveDependencies,
          orderId: orderId,
        );

  CanReviewProvider._internal(
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
  Override overrideWith(
    FutureOr<CanReviewResponse> Function(CanReviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CanReviewProvider._internal(
        (ref) => create(ref as CanReviewRef),
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
  AutoDisposeFutureProviderElement<CanReviewResponse> createElement() {
    return _CanReviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CanReviewProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CanReviewRef on AutoDisposeFutureProviderRef<CanReviewResponse> {
  /// The parameter `orderId` of this provider.
  int get orderId;
}

class _CanReviewProviderElement
    extends AutoDisposeFutureProviderElement<CanReviewResponse>
    with CanReviewRef {
  _CanReviewProviderElement(super.provider);

  @override
  int get orderId => (origin as CanReviewProvider).orderId;
}

String _$restaurantReviewsHash() => r'a8d1f3102b128004dd5375e89aceeeea1905532c';

abstract class _$RestaurantReviews
    extends BuildlessAutoDisposeAsyncNotifier<ReviewListResponse> {
  late final int restaurantId;

  FutureOr<ReviewListResponse> build(
    int restaurantId,
  );
}

/// Restaurant reviews provider
///
/// Copied from [RestaurantReviews].
@ProviderFor(RestaurantReviews)
const restaurantReviewsProvider = RestaurantReviewsFamily();

/// Restaurant reviews provider
///
/// Copied from [RestaurantReviews].
class RestaurantReviewsFamily extends Family<AsyncValue<ReviewListResponse>> {
  /// Restaurant reviews provider
  ///
  /// Copied from [RestaurantReviews].
  const RestaurantReviewsFamily();

  /// Restaurant reviews provider
  ///
  /// Copied from [RestaurantReviews].
  RestaurantReviewsProvider call(
    int restaurantId,
  ) {
    return RestaurantReviewsProvider(
      restaurantId,
    );
  }

  @override
  RestaurantReviewsProvider getProviderOverride(
    covariant RestaurantReviewsProvider provider,
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
  String? get name => r'restaurantReviewsProvider';
}

/// Restaurant reviews provider
///
/// Copied from [RestaurantReviews].
class RestaurantReviewsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    RestaurantReviews, ReviewListResponse> {
  /// Restaurant reviews provider
  ///
  /// Copied from [RestaurantReviews].
  RestaurantReviewsProvider(
    int restaurantId,
  ) : this._internal(
          () => RestaurantReviews()..restaurantId = restaurantId,
          from: restaurantReviewsProvider,
          name: r'restaurantReviewsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$restaurantReviewsHash,
          dependencies: RestaurantReviewsFamily._dependencies,
          allTransitiveDependencies:
              RestaurantReviewsFamily._allTransitiveDependencies,
          restaurantId: restaurantId,
        );

  RestaurantReviewsProvider._internal(
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
  FutureOr<ReviewListResponse> runNotifierBuild(
    covariant RestaurantReviews notifier,
  ) {
    return notifier.build(
      restaurantId,
    );
  }

  @override
  Override overrideWith(RestaurantReviews Function() create) {
    return ProviderOverride(
      origin: this,
      override: RestaurantReviewsProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<RestaurantReviews, ReviewListResponse>
      createElement() {
    return _RestaurantReviewsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RestaurantReviewsProvider &&
        other.restaurantId == restaurantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, restaurantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RestaurantReviewsRef
    on AutoDisposeAsyncNotifierProviderRef<ReviewListResponse> {
  /// The parameter `restaurantId` of this provider.
  int get restaurantId;
}

class _RestaurantReviewsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RestaurantReviews,
        ReviewListResponse> with RestaurantReviewsRef {
  _RestaurantReviewsProviderElement(super.provider);

  @override
  int get restaurantId => (origin as RestaurantReviewsProvider).restaurantId;
}

String _$myReviewsHash() => r'79d56b4e72771ce76b40073e23492ce58c883153';

/// My reviews provider
///
/// Copied from [MyReviews].
@ProviderFor(MyReviews)
final myReviewsProvider =
    AutoDisposeAsyncNotifierProvider<MyReviews, List<ReviewModel>>.internal(
  MyReviews.new,
  name: r'myReviewsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myReviewsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MyReviews = AutoDisposeAsyncNotifier<List<ReviewModel>>;
String _$createReviewHash() => r'aa1503be338c660cbf585c073bb03c75bb0f9046';

/// Create review notifier
///
/// Copied from [CreateReview].
@ProviderFor(CreateReview)
final createReviewProvider = AutoDisposeNotifierProvider<CreateReview,
    AsyncValue<ReviewModel?>>.internal(
  CreateReview.new,
  name: r'createReviewProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$createReviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateReview = AutoDisposeNotifier<AsyncValue<ReviewModel?>>;
String _$updateReviewHash() => r'a3edf28922956465843d07688f14fb6ab3f70ea4';

/// Update review notifier
///
/// Copied from [UpdateReview].
@ProviderFor(UpdateReview)
final updateReviewProvider = AutoDisposeNotifierProvider<UpdateReview,
    AsyncValue<ReviewModel?>>.internal(
  UpdateReview.new,
  name: r'updateReviewProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$updateReviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UpdateReview = AutoDisposeNotifier<AsyncValue<ReviewModel?>>;
String _$deleteReviewHash() => r'0568b4e5e796a618ee2378739b00c8e358560e8f';

/// Delete review notifier
///
/// Copied from [DeleteReview].
@ProviderFor(DeleteReview)
final deleteReviewProvider =
    AutoDisposeNotifierProvider<DeleteReview, AsyncValue<void>>.internal(
  DeleteReview.new,
  name: r'deleteReviewProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$deleteReviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeleteReview = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
