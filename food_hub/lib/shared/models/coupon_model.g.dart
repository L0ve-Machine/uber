// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponModel _$CouponModelFromJson(Map<String, dynamic> json) => CouponModel(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: (json['min_order_amount'] as num).toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
    );

Map<String, dynamic> _$CouponModelToJson(CouponModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'discount_type': instance.discountType,
      'discount_value': instance.discountValue,
      'min_order_amount': instance.minOrderAmount,
      'max_discount': instance.maxDiscount,
      'end_date': instance.endDate?.toIso8601String(),
    };

ValidateCouponRequest _$ValidateCouponRequestFromJson(
        Map<String, dynamic> json) =>
    ValidateCouponRequest(
      code: json['code'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
    );

Map<String, dynamic> _$ValidateCouponRequestToJson(
        ValidateCouponRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'subtotal': instance.subtotal,
    };

ValidateCouponResponse _$ValidateCouponResponseFromJson(
        Map<String, dynamic> json) =>
    ValidateCouponResponse(
      coupon: CouponModel.fromJson(json['coupon'] as Map<String, dynamic>),
      discount: (json['discount'] as num).toInt(),
    );

Map<String, dynamic> _$ValidateCouponResponseToJson(
        ValidateCouponResponse instance) =>
    <String, dynamic>{
      'coupon': instance.coupon,
      'discount': instance.discount,
    };
