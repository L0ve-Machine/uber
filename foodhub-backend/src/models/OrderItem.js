const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const OrderItem = sequelize.define('OrderItem', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  order_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'orders',
      key: 'id',
    },
  },
  menu_item_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'menu_items',
      key: 'id',
    },
  },
  quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1,
  },
  unit_price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  total_price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  selected_options: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  special_request: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'order_items',
  timestamps: false,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
OrderItem.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['unit_price', 'total_price'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  // Handle selected_options price field
  if (values.selected_options && Array.isArray(values.selected_options)) {
    values.selected_options = values.selected_options.map(opt => ({
      ...opt,
      price: opt.price !== null && opt.price !== undefined ? parseFloat(opt.price) : opt.price
    }));
  }

  return values;
};

module.exports = OrderItem;
