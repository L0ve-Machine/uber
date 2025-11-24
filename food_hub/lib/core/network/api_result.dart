import 'api_error.dart';

/// Result type for API calls
/// Either Success<T> or Failure
sealed class ApiResult<T> {
  const ApiResult();

  /// Execute callback based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).error);
    }
  }

  /// Execute callback only on success
  R? whenSuccess<R>(R Function(T data) callback) {
    if (this is Success<T>) {
      return callback((this as Success<T>).data);
    }
    return null;
  }

  /// Execute callback only on failure
  R? whenFailure<R>(R Function(ApiError error) callback) {
    if (this is Failure<T>) {
      return callback((this as Failure<T>).error);
    }
    return null;
  }

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data or null
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;

  /// Get error or null
  ApiError? get errorOrNull => isFailure ? (this as Failure<T>).error : null;
}

/// Success result
class Success<T> extends ApiResult<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success(data: $data)';
}

/// Failure result
class Failure<T> extends ApiResult<T> {
  final ApiError error;

  const Failure(this.error);

  @override
  String toString() => 'Failure(error: $error)';
}
