const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Order = sequelize.define('Order', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  order_number: {
    type: DataTypes.STRING(20),
    allowNull: false,
    unique: true,
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'customers',
      key: 'id',
    },
  },
  restaurant_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'restaurants',
      key: 'id',
    },
  },
  driver_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'drivers',
      key: 'id',
    },
  },
  delivery_address_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'customer_addresses',
      key: 'id',
    },
  },
  status: {
    type: DataTypes.ENUM(
      'pending',
      'accepted',
      'preparing',
      'ready',
      'picked_up',
      'delivering',
      'delivered',
      'cancelled'
    ),
    defaultValue: 'pending',
  },
  subtotal: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  delivery_fee: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  tax: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  discount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
  },
  total: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  payment_method: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  stripe_payment_id: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  special_instructions: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  scheduled_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  accepted_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  picked_up_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  delivered_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  cancelled_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  pickup_pin: {
    type: DataTypes.STRING(4),
    allowNull: true,
    comment: 'ピックアップ確認用4桁PIN（statusがreadyになった時に生成）',
  },
  pin_verified_at: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'PINが確認された日時',
  },
}, {
  tableName: 'orders',
  timestamps: true,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
Order.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['subtotal', 'delivery_fee', 'tax', 'discount', 'total'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  return values;
};

module.exports = Order;
