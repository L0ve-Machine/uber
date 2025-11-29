// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileApiServiceHash() => r'b07a35943a82afd6afd4f10ad919602f556e5ec4';

/// ProfileApiService provider
///
/// Copied from [profileApiService].
@ProviderFor(profileApiService)
final profileApiServiceProvider =
    AutoDisposeProvider<ProfileApiService>.internal(
  profileApiService,
  name: r'profileApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileApiServiceRef = AutoDisposeProviderRef<ProfileApiService>;
String _$profileRepositoryHash() => r'b73b27f308928bfdd657ca3112119d9f659118f2';

/// ProfileRepository provider
///
/// Copied from [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider =
    AutoDisposeProvider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileRepositoryRef = AutoDisposeProviderRef<ProfileRepository>;
String _$profileHash() => r'e0b2ae73763aedf17c5e3f43117a7bc86382ff5f';

/// Profile provider
///
/// Copied from [Profile].
@ProviderFor(Profile)
final profileProvider =
    AutoDisposeAsyncNotifierProvider<Profile, UserModel>.internal(
  Profile.new,
  name: r'profileProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$profileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Profile = AutoDisposeAsyncNotifier<UserModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
