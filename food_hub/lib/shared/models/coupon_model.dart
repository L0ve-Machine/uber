import 'package:json_annotation/json_annotation.dart';

part 'coupon_model.g.dart';

@JsonSerializable()
class CouponModel {
  final int id;

  final String code;

  @JsonKey(name: 'discount_type')
  final String discountType;

  @JsonKey(name: 'discount_value')
  final double discountValue;

  @JsonKey(name: 'min_order_amount')
  final double minOrderAmount;

  @JsonKey(name: 'max_discount')
  final double? maxDiscount;

  @JsonKey(name: 'end_date')
  final DateTime? endDate;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscount,
    this.endDate,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) =>
      _$CouponModelFromJson(json);

  Map<String, dynamic> toJson() => _$CouponModelToJson(this);

  /// 割引の説明文を取得
  String get discountDescription {
    if (discountType == 'percent') {
      final percentOff = discountValue.toInt();
      if (maxDiscount != null) {
        return '$percentOff%OFF (最大¥${maxDiscount!.toInt()})';
      }
      return '$percentOff%OFF';
    } else {
      return '¥${discountValue.toInt()}OFF';
    }
  }

  /// 使用条件の説明文を取得
  String get conditionDescription {
    if (minOrderAmount > 0) {
      return '¥${minOrderAmount.toInt()}以上の注文で使用可能';
    }
    return '全ての注文で使用可能';
  }

  /// 有効期限が近いかどうか（3日以内）
  bool get isExpiringSoon {
    if (endDate == null) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }
}

@JsonSerializable()
class ValidateCouponRequest {
  final String code;
  final double subtotal;

  ValidateCouponRequest({
    required this.code,
    required this.subtotal,
  });

  factory ValidateCouponRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidateCouponRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateCouponRequestToJson(this);
}

@JsonSerializable()
class ValidateCouponResponse {
  final CouponModel coupon;
  final int discount;

  ValidateCouponResponse({
    required this.coupon,
    required this.discount,
  });

  factory ValidateCouponResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateCouponResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateCouponResponseToJson(this);
}
