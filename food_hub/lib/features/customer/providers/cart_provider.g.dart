// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartItemCountHash() => r'ffe8fd6b755e55e14e1e1aecfa8fde3dca81634f';

/// Cart item count provider (for badge)
///
/// Copied from [cartItemCount].
@ProviderFor(cartItemCount)
final cartItemCountProvider = AutoDisposeProvider<int>.internal(
  cartItemCount,
  name: r'cartItemCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartItemCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CartItemCountRef = AutoDisposeProviderRef<int>;
String _$cartTotalQuantityHash() => r'4b1e6d2aafacfb701b4ff01966147e60418f2326';

/// Cart total quantity provider
///
/// Copied from [cartTotalQuantity].
@ProviderFor(cartTotalQuantity)
final cartTotalQuantityProvider = AutoDisposeProvider<int>.internal(
  cartTotalQuantity,
  name: r'cartTotalQuantityProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartTotalQuantityHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CartTotalQuantityRef = AutoDisposeProviderRef<int>;
String _$cartSubtotalHash() => r'97951f3b697a6a5fe31f1806c30f6df2bdea4f09';

/// Cart subtotal provider
///
/// Copied from [cartSubtotal].
@ProviderFor(cartSubtotal)
final cartSubtotalProvider = AutoDisposeProvider<double>.internal(
  cartSubtotal,
  name: r'cartSubtotalProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartSubtotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CartSubtotalRef = AutoDisposeProviderRef<double>;
String _$cartTotalHash() => r'd5f4889d6eb62d0d177c57f2cd93e2f27caf6a4d';

/// Cart total provider
///
/// Copied from [cartTotal].
@ProviderFor(cartTotal)
final cartTotalProvider = AutoDisposeProvider<double>.internal(
  cartTotal,
  name: r'cartTotalProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartTotalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CartTotalRef = AutoDisposeProviderRef<double>;
String _$cartHash() => r'd6dfc91e902ee9700e28525e8aff4010e3f8603c';

/// Cart Provider - manages shopping cart state
///
/// Copied from [Cart].
@ProviderFor(Cart)
final cartProvider = AutoDisposeNotifierProvider<Cart, List<CartItem>>.internal(
  Cart.new,
  name: r'cartProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Cart = AutoDisposeNotifier<List<CartItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
