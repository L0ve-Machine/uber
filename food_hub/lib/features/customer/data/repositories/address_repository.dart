import '../../../../core/network/api_result.dart';
import '../../../../shared/models/address_model.dart';
import '../services/address_api_service.dart';

/// Address Repository
class AddressRepository {
  final AddressApiService _apiService;

  AddressRepository({required AddressApiService apiService})
      : _apiService = apiService;

  /// Get customer's addresses
  Future<ApiResult<List<AddressModel>>> getAddresses(int customerId) async {
    return await _apiService.getAddresses(customerId);
  }

  /// Add new address
  Future<ApiResult<AddressModel>> addAddress({
    required int customerId,
    required String addressLine,
    required String city,
    required String postalCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
    String label = 'Home',
  }) async {
    return await _apiService.addAddress(
      customerId: customerId,
      addressLine: addressLine,
      city: city,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      label: label,
    );
  }

  /// Update address
  Future<ApiResult<AddressModel>> updateAddress({
    required int addressId,
    required String addressLine,
    required String city,
    required String postalCode,
    double? latitude,
    double? longitude,
    String? label,
  }) async {
    return await _apiService.updateAddress(
      addressId: addressId,
      addressLine: addressLine,
      city: city,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  /// Delete address
  Future<ApiResult<void>> deleteAddress(int addressId) async {
    return await _apiService.deleteAddress(addressId);
  }

  /// Set address as default
  Future<ApiResult<AddressModel>> setDefaultAddress(int addressId) async {
    return await _apiService.setDefaultAddress(addressId);
  }
}
