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
};
