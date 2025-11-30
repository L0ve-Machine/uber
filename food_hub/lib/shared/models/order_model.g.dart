// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
      id: (json['id'] as num).toInt(),
      orderNumber: json['order_number'] as String,
      customerId: (json['customer_id'] as num).toInt(),
      restaurantId: (json['restaurant_id'] as num).toInt(),
      driverId: (json['driver_id'] as num?)?.toInt(),
      deliveryAddressId: (json['delivery_address_id'] as num).toInt(),
      status: json['status'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      stripePaymentId: json['stripe_payment_id'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
      pickedUpAt: json['picked_up_at'] == null
          ? null
          : DateTime.parse(json['picked_up_at'] as String),
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: json['delivery_address'] == null
          ? null
          : AddressModel.fromJson(
              json['delivery_address'] as Map<String, dynamic>),
      restaurant: json['restaurant'] == null
          ? null
          : RestaurantBasicModel.fromJson(
              json['restaurant'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'customer_id': instance.customerId,
      'restaurant_id': instance.restaurantId,
      'driver_id': instance.driverId,
      'delivery_address_id': instance.deliveryAddressId,
      'status': instance.status,
      'subtotal': instance.subtotal,
      'delivery_fee': instance.deliveryFee,
      'service_fee': instance.serviceFee,
      'tax': instance.tax,
      'discount': instance.discount,
      'total': instance.total,
      'payment_method': instance.paymentMethod,
      'stripe_payment_id': instance.stripePaymentId,
      'special_instructions': instance.specialInstructions,
      'scheduled_at': instance.scheduledAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'picked_up_at': instance.pickedUpAt?.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'items': instance.items,
      'delivery_address': instance.deliveryAddress,
      'restaurant': instance.restaurant,
    };

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      menuItemId: (json['menu_item_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      selectedOptions: (json['selected_options'] as List<dynamic>?)
          ?.map((e) => SelectedOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialRequest: json['special_request'] as String?,
      menuItem: json['menu_item'] == null
          ? null
          : MenuItemModel.fromJson(json['menu_item'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'menu_item_id': instance.menuItemId,
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total_price': instance.totalPrice,
      'selected_options': instance.selectedOptions,
      'special_request': instance.specialRequest,
      'menu_item': instance.menuItem,
    };

SelectedOptionModel _$SelectedOptionModelFromJson(Map<String, dynamic> json) =>
    SelectedOptionModel(
      group: json['group'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );

Map<String, dynamic> _$SelectedOptionModelToJson(
        SelectedOptionModel instance) =>
    <String, dynamic>{
      'group': instance.group,
      'name': instance.name,
      'price': instance.price,
    };

RestaurantBasicModel _$RestaurantBasicModelFromJson(
        Map<String, dynamic> json) =>
    RestaurantBasicModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RestaurantBasicModelToJson(
        RestaurantBasicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl,
      'phone': instance.phone,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
