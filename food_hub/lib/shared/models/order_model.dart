import 'package:json_annotation/json_annotation.dart';
import 'menu_item_model.dart';
import 'address_model.dart';

part 'order_model.g.dart';

/// Helper function to parse double values that might come as String from MySQL
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

@JsonSerializable()
class OrderModel {
  final int id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'delivery_address_id')
  final int deliveryAddressId;
  final String status;
  @JsonKey(fromJson: _parseDouble)
  final double subtotal;
  @JsonKey(name: 'delivery_fee', fromJson: _parseDouble)
  final double deliveryFee;
  @JsonKey(name: 'service_fee', fromJson: _parseDouble)
  final double? serviceFee;
  @JsonKey(fromJson: _parseDouble)
  final double tax;
  @JsonKey(fromJson: _parseDouble)
  final double discount;
  @JsonKey(fromJson: _parseDouble)
  final double total;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'stripe_payment_id')
  final String? stripePaymentId;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'scheduled_at')
  final DateTime? scheduledAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  @JsonKey(name: 'picked_up_at')
  final DateTime? pickedUpAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  // Associations
  final List<OrderItemModel>? items;
  @JsonKey(name: 'delivery_address')
  final AddressModel? deliveryAddress;
  final RestaurantBasicModel? restaurant;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.restaurantId,
    this.driverId,
    required this.deliveryAddressId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    this.serviceFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.stripePaymentId,
    this.specialInstructions,
    this.scheduledAt,
    required this.createdAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.items,
    this.deliveryAddress,
    this.restaurant,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable()
class OrderItemModel {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'menu_item_id')
  final int menuItemId;
  final int quantity;
  @JsonKey(name: 'unit_price', fromJson: _parseDouble)
  final double unitPrice;
  @JsonKey(name: 'total_price', fromJson: _parseDouble)
  final double totalPrice;
  @JsonKey(name: 'selected_options')
  final List<SelectedOptionModel>? selectedOptions;
  @JsonKey(name: 'special_request')
  final String? specialRequest;

  // Association
  @JsonKey(name: 'menu_item')
  final MenuItemModel? menuItem;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.selectedOptions,
    this.specialRequest,
    this.menuItem,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}

@JsonSerializable()
class SelectedOptionModel {
  final String group;
  final String name;
  final double price;

  SelectedOptionModel({
    required this.group,
    required this.name,
    required this.price,
  });

  factory SelectedOptionModel.fromJson(Map<String, dynamic> json) =>
      _$SelectedOptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SelectedOptionModelToJson(this);
}

@JsonSerializable()
class RestaurantBasicModel {
  final int id;
  final String name;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;

  RestaurantBasicModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory RestaurantBasicModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantBasicModelFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantBasicModelToJson(this);
}
