// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authApiServiceHash() => r'c37755d8129a8316ba74ddaf3299578ad04b0c3f';

/// AuthApiService provider
///
/// Copied from [authApiService].
@ProviderFor(authApiService)
final authApiServiceProvider = AutoDisposeProvider<AuthApiService>.internal(
  authApiService,
  name: r'authApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthApiServiceRef = AutoDisposeProviderRef<AuthApiService>;
String _$authRepositoryHash() => r'482d578c3e6a2cefae7b9d4f4a7321a3da9cd01f';

/// AuthRepository provider
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$isAuthenticatedHash() => r'2073c9fee5e9026eef440f18d32e328e86c45570';

/// Check if user is authenticated
///
/// Copied from [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeFutureProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsAuthenticatedRef = AutoDisposeFutureProviderRef<bool>;
String _$authHash() => r'4e557250220c958e940170a2cd89988f00e19211';

/// Auth state provider
/// Manages current user authentication state
///
/// Copied from [Auth].
@ProviderFor(Auth)
final authProvider =
    AutoDisposeAsyncNotifierProvider<Auth, UserModel?>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Auth = AutoDisposeAsyncNotifier<UserModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
