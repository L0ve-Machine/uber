// Model associations
const Customer = require('./Customer');
const Restaurant = require('./Restaurant');
const Driver = require('./Driver');
const MenuItem = require('./MenuItem');
const MenuItemOption = require('./MenuItemOption');
const CustomerAddress = require('./CustomerAddress');
const Order = require('./Order');
const OrderItem = require('./OrderItem');
const Favorite = require('./Favorite');
const Review = require('./Review');
const Coupon = require('./Coupon');
const CouponUsage = require('./CouponUsage');

// Customer - CustomerAddress (One-to-Many)
Customer.hasMany(CustomerAddress, {
  foreignKey: 'customer_id',
  as: 'addresses',
});
CustomerAddress.belongsTo(Customer, {
  foreignKey: 'customer_id',
  as: 'customer',
});

// Restaurant - MenuItem (One-to-Many)
Restaurant.hasMany(MenuItem, {
  foreignKey: 'restaurant_id',
  as: 'menu_items',
});
MenuItem.belongsTo(Restaurant, {
  foreignKey: 'restaurant_id',
  as: 'restaurant',
});

// MenuItem - MenuItemOption (One-to-Many)
MenuItem.hasMany(MenuItemOption, {
  foreignKey: 'menu_item_id',
  as: 'options',
});
MenuItemOption.belongsTo(MenuItem, {
  foreignKey: 'menu_item_id',
  as: 'menu_item',
});

// Order - Customer (Many-to-One)
Order.belongsTo(Customer, {
  foreignKey: 'customer_id',
  as: 'customer',
});

// Order - Restaurant (Many-to-One)
Order.belongsTo(Restaurant, {
  foreignKey: 'restaurant_id',
  as: 'restaurant',
});

// Order - Driver (Many-to-One)
Order.belongsTo(Driver, {
  foreignKey: 'driver_id',
  as: 'driver',
});

// Order - CustomerAddress (Many-to-One)
Order.belongsTo(CustomerAddress, {
  foreignKey: 'delivery_address_id',
  as: 'delivery_address',
});

// Order - OrderItem (One-to-Many)
Order.hasMany(OrderItem, {
  foreignKey: 'order_id',
  as: 'items',
});
OrderItem.belongsTo(Order, {
  foreignKey: 'order_id',
  as: 'order',
});

// OrderItem - MenuItem (Many-to-One)
OrderItem.belongsTo(MenuItem, {
  foreignKey: 'menu_item_id',
  as: 'menu_item',
});

// Favorite - Customer (Many-to-One)
Favorite.belongsTo(Customer, {
  foreignKey: 'customer_id',
  as: 'customer',
});

// Favorite - Restaurant (Many-to-One)
Favorite.belongsTo(Restaurant, {
  foreignKey: 'restaurant_id',
  as: 'restaurant',
});

// Review - Customer (Many-to-One)
Review.belongsTo(Customer, {
  foreignKey: 'customer_id',
  as: 'customer',
});

// Review - Restaurant (Many-to-One)
Review.belongsTo(Restaurant, {
  foreignKey: 'restaurant_id',
  as: 'restaurant',
});

// Review - Order (One-to-One)
Review.belongsTo(Order, {
  foreignKey: 'order_id',
  as: 'order',
});

// Order - Review (One-to-One)
Order.hasOne(Review, {
  foreignKey: 'order_id',
  as: 'review',
});

// Restaurant - Reviews (One-to-Many)
Restaurant.hasMany(Review, {
  foreignKey: 'restaurant_id',
  as: 'reviews',
});

// Coupon - CouponUsage (One-to-Many)
Coupon.hasMany(CouponUsage, {
  foreignKey: 'coupon_id',
  as: 'usages',
});
CouponUsage.belongsTo(Coupon, {
  foreignKey: 'coupon_id',
  as: 'coupon',
});

// Customer - CouponUsage (One-to-Many)
Customer.hasMany(CouponUsage, {
  foreignKey: 'customer_id',
  as: 'coupon_usages',
});
CouponUsage.belongsTo(Customer, {
  foreignKey: 'customer_id',
  as: 'customer',
});

// Order - CouponUsage (One-to-One)
Order.hasOne(CouponUsage, {
  foreignKey: 'order_id',
  as: 'coupon_usage',
});
CouponUsage.belongsTo(Order, {
  foreignKey: 'order_id',
  as: 'order',
});

module.exports = {
  Customer,
  Restaurant,
  Driver,
  MenuItem,
  MenuItemOption,
  CustomerAddress,
  Order,
  OrderItem,
  Favorite,
  Review,
  Coupon,
  CouponUsage,
};
