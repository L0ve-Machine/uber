// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$addressApiServiceHash() => r'371ba0b2a8b88db47203819fb1a557f7d232a4f8';

/// AddressApiService provider
///
/// Copied from [addressApiService].
@ProviderFor(addressApiService)
final addressApiServiceProvider =
    AutoDisposeProvider<AddressApiService>.internal(
  addressApiService,
  name: r'addressApiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addressApiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AddressApiServiceRef = AutoDisposeProviderRef<AddressApiService>;
String _$addressRepositoryHash() => r'889217309e324539a07dabe5c0ad43bfaa1ef7aa';

/// AddressRepository provider
///
/// Copied from [addressRepository].
@ProviderFor(addressRepository)
final addressRepositoryProvider =
    AutoDisposeProvider<AddressRepository>.internal(
  addressRepository,
  name: r'addressRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addressRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AddressRepositoryRef = AutoDisposeProviderRef<AddressRepository>;
String _$defaultAddressHash() => r'7bfae34552402ab3507041ba6da5cbf87c2a4a6e';

/// Default address provider
///
/// Copied from [defaultAddress].
@ProviderFor(defaultAddress)
final defaultAddressProvider =
    AutoDisposeFutureProvider<AddressModel?>.internal(
  defaultAddress,
  name: r'defaultAddressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultAddressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DefaultAddressRef = AutoDisposeFutureProviderRef<AddressModel?>;
String _$addressListHash() => r'059d635d236916270f31ec010c773d243665e98b';

/// Address list provider
///
/// Copied from [AddressList].
@ProviderFor(AddressList)
final addressListProvider =
    AutoDisposeAsyncNotifierProvider<AddressList, List<AddressModel>>.internal(
  AddressList.new,
  name: r'addressListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$addressListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddressList = AutoDisposeAsyncNotifier<List<AddressModel>>;
String _$selectedAddressHash() => r'04de7a9d2a46400f1b25a108649e10e17aa5c9ce';

/// Selected address provider for checkout
///
/// Copied from [SelectedAddress].
@ProviderFor(SelectedAddress)
final selectedAddressProvider =
    AutoDisposeNotifierProvider<SelectedAddress, AddressModel?>.internal(
  SelectedAddress.new,
  name: r'selectedAddressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedAddressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedAddress = AutoDisposeNotifier<AddressModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
