import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/address_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/repositories/address_repository.dart';
import '../data/services/address_api_service.dart';

part 'address_provider.g.dart';

/// AddressApiService provider
@riverpod
AddressApiService addressApiService(AddressApiServiceRef ref) {
  return AddressApiService(ref.watch(dioProvider));
}

/// AddressRepository provider
@riverpod
AddressRepository addressRepository(AddressRepositoryRef ref) {
  return AddressRepository(
    apiService: ref.watch(addressApiServiceProvider),
  );
}

/// Address list provider
@riverpod
class AddressList extends _$AddressList {
  @override
  Future<List<AddressModel>> build() async {
    final user = await ref.watch(authProvider.future);
    if (user == null) {
      return [];
    }

    final repository = ref.read(addressRepositoryProvider);
    final result = await repository.getAddresses(user.id);

    return result.when(
      success: (addresses) => addresses,
      failure: (error) => throw error,
    );
  }

  /// Refresh address list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  /// Add new address
  Future<ApiResult<AddressModel>> addAddress({
    required String addressLine1,
    String? addressLine2,
    required String postalCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
    String label = 'Home',
  }) async {
    final user = await ref.read(authProvider.future);
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final repository = ref.read(addressRepositoryProvider);
    final result = await repository.addAddress(
      customerId: user.id,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      label: label,
    );

    result.when(
      success: (_) {
        // Refresh the list
        ref.invalidateSelf();
      },
      failure: (_) {},
    );

    return result;
  }

  /// Delete address
  Future<ApiResult<void>> deleteAddress(int addressId) async {
    final repository = ref.read(addressRepositoryProvider);
    final result = await repository.deleteAddress(addressId);

    result.when(
      success: (_) {
        // Refresh the list
        ref.invalidateSelf();
      },
      failure: (_) {},
    );

    return result;
  }

  /// Set address as default
  Future<ApiResult<AddressModel>> setDefaultAddress(int addressId) async {
    final repository = ref.read(addressRepositoryProvider);
    final result = await repository.setDefaultAddress(addressId);

    result.when(
      success: (_) {
        // Refresh the list
        ref.invalidateSelf();
      },
      failure: (_) {},
    );

    return result;
  }
}

/// Selected address provider for checkout
@riverpod
class SelectedAddress extends _$SelectedAddress {
  @override
  AddressModel? build() {
    return null;
  }

  /// Set selected address
  void setAddress(AddressModel address) {
    state = address;
  }

  /// Clear selected address
  void clear() {
    state = null;
  }
}

/// Default address provider
@riverpod
Future<AddressModel?> defaultAddress(DefaultAddressRef ref) async {
  final addresses = await ref.watch(addressListProvider.future);

  if (addresses.isEmpty) {
    return null;
  }

  // Find default address or return first one
  final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
  return defaultAddr ?? addresses.first;
}
