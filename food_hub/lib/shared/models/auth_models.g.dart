// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      userType: json['user_type'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'user_type': instance.userType,
    };

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      message: json['message'] as String,
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      userType: json['user_type'] as String,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'token': instance.token,
      'user': instance.user,
      'user_type': instance.userType,
    };

RegisterCustomerRequest _$RegisterCustomerRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterCustomerRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$RegisterCustomerRequestToJson(
        RegisterCustomerRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'full_name': instance.fullName,
      'phone': instance.phone,
    };

RegisterRestaurantRequest _$RegisterRestaurantRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterRestaurantRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$RegisterRestaurantRequestToJson(
        RegisterRestaurantRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'phone': instance.phone,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

RegisterDriverRequest _$RegisterDriverRequestFromJson(
        Map<String, dynamic> json) =>
    RegisterDriverRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      vehicleType: json['vehicle_type'] as String,
      licenseNumber: json['license_number'] as String,
    );

Map<String, dynamic> _$RegisterDriverRequestToJson(
        RegisterDriverRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'vehicle_type': instance.vehicleType,
      'license_number': instance.licenseNumber,
    };
