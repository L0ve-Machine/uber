import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

/// Login request
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  @JsonKey(name: 'user_type')
  final String userType;

  LoginRequest({
    required this.email,
    required this.password,
    required this.userType,
  });

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/// Login response
@JsonSerializable()
class LoginResponse {
  final String message;
  final String token;
  final UserModel user;
  @JsonKey(name: 'user_type')
  final String userType;

  LoginResponse({
    required this.message,
    required this.token,
    required this.user,
    required this.userType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

/// Register customer request
@JsonSerializable()
class RegisterCustomerRequest {
  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String phone;

  RegisterCustomerRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  Map<String, dynamic> toJson() => _$RegisterCustomerRequestToJson(this);
}

/// Register restaurant request
@JsonSerializable()
class RegisterRestaurantRequest {
  final String email;
  final String password;
  final String name;
  final String? description;
  final String category;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;

  RegisterRestaurantRequest({
    required this.email,
    required this.password,
    required this.name,
    this.description,
    required this.category,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => _$RegisterRestaurantRequestToJson(this);
}

/// Register driver request
@JsonSerializable()
class RegisterDriverRequest {
  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String phone;
  @JsonKey(name: 'vehicle_type')
  final String vehicleType;
  @JsonKey(name: 'license_number')
  final String licenseNumber;

  RegisterDriverRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    required this.licenseNumber,
  });

  Map<String, dynamic> toJson() => _$RegisterDriverRequestToJson(this);
}

/// Register response (same as login response)
typedef RegisterResponse = LoginResponse;
