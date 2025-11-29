import 'package:dio/dio.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../shared/models/address_model.dart';

/// Address API Service
class AddressApiService {
  final Dio _dio;

  AddressApiService(this._dio);

  /// Get customer's addresses
  Future<ApiResult<List<AddressModel>>> getAddresses(int customerId) async {
    try {
      print('[ADDRESS] Fetching addresses for customer: $customerId');
      final response = await _dio.get('/customers/$customerId/addresses');
      print('[ADDRESS] Response status: ${response.statusCode}');
      print('[ADDRESS] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final addressesList = data['addresses'] as List<dynamic>? ?? [];

        final addresses = addressesList
            .map((json) => AddressModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return Success(addresses);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      print('[ADDRESS] DioException: ${e.message}');
      print('[ADDRESS] DioException response: ${e.response?.data}');
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      print('[ADDRESS] Unexpected error: $e');
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
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
    try {
      final response = await _dio.post(
        '/customers/$customerId/addresses',
        data: {
          'address_line': addressLine,
          'city': city,
          'postal_code': postalCode,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'is_default': isDefault,
          'label': label,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final address = AddressModel.fromJson(data['address'] as Map<String, dynamic>);
        return Success(address);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
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
    try {
      final response = await _dio.put(
        '/addresses/$addressId',
        data: {
          'address_line': addressLine,
          'city': city,
          'postal_code': postalCode,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (label != null) 'label': label,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final address = AddressModel.fromJson(data['address'] as Map<String, dynamic>);
        return Success(address);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Delete address
  Future<ApiResult<void>> deleteAddress(int addressId) async {
    try {
      final response = await _dio.delete('/addresses/$addressId');

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }

  /// Set address as default
  Future<ApiResult<AddressModel>> setDefaultAddress(int addressId) async {
    try {
      final response = await _dio.patch('/addresses/$addressId/default');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final address = AddressModel.fromJson(data['address'] as Map<String, dynamic>);
        return Success(address);
      }

      return Failure(ApiError.fromResponse(response.statusCode, response.data));
    } on DioException catch (e) {
      return Failure(ApiError.fromDioException(e));
    } catch (e) {
      return Failure(ApiError(message: 'Unexpected error: $e'));
    }
  }
}
