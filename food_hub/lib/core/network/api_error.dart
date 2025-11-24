import 'package:dio/dio.dart';

/// API Error model
class ApiError {
  final String message;
  final int? statusCode;
  final String? errorType;
  final List<ValidationError>? validationErrors;

  ApiError({
    required this.message,
    this.statusCode,
    this.errorType,
    this.validationErrors,
  });

  /// Create ApiError from DioException
  factory ApiError.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          message: 'Connection timeout. Please try again.',
          statusCode: null,
          errorType: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        return ApiError.fromResponse(
          exception.response?.statusCode,
          exception.response?.data,
        );

      case DioExceptionType.cancel:
        return ApiError(
          message: 'Request cancelled',
          statusCode: null,
          errorType: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return ApiError(
          message: 'No internet connection. Please check your network.',
          statusCode: null,
          errorType: 'NO_INTERNET',
        );

      default:
        return ApiError(
          message: 'Something went wrong. Please try again.',
          statusCode: null,
          errorType: 'UNKNOWN',
        );
    }
  }

  /// Create ApiError from HTTP response
  factory ApiError.fromResponse(int? statusCode, dynamic responseData) {
    String message = 'An error occurred';
    List<ValidationError>? validationErrors;

    if (responseData is Map<String, dynamic>) {
      // Single error message
      if (responseData.containsKey('error')) {
        message = responseData['error'] as String;
      }
      // Validation errors array
      else if (responseData.containsKey('errors')) {
        final errors = responseData['errors'] as List<dynamic>;
        validationErrors = errors
            .map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
            .toList();
        message = 'Validation failed';
      }
      // Generic message
      else if (responseData.containsKey('message')) {
        message = responseData['message'] as String;
      }
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      errorType: _getErrorType(statusCode),
      validationErrors: validationErrors,
    );
  }

  static String _getErrorType(int? statusCode) {
    if (statusCode == null) return 'UNKNOWN';

    if (statusCode >= 500) return 'SERVER_ERROR';
    if (statusCode == 401) return 'UNAUTHORIZED';
    if (statusCode == 403) return 'FORBIDDEN';
    if (statusCode == 404) return 'NOT_FOUND';
    if (statusCode == 409) return 'CONFLICT';
    if (statusCode >= 400) return 'BAD_REQUEST';

    return 'UNKNOWN';
  }

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.map((e) => e.msg).join(', ');
    }
    return message;
  }
}

/// Validation error from express-validator
class ValidationError {
  final String msg;
  final String? param;
  final dynamic value;

  ValidationError({
    required this.msg,
    this.param,
    this.value,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      msg: json['msg'] as String,
      param: json['param'] as String?,
      value: json['value'],
    );
  }
}
