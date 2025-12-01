const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Coupon = sequelize.define('Coupon', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  code: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true,
  },
  discount_type: {
    type: DataTypes.ENUM('percent', 'fixed'),
    allowNull: false,
  },
  discount_value: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  min_order_amount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  max_discount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  start_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  end_date: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  usage_limit: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  per_user_limit: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'coupons',
  timestamps: true,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
Coupon.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['discount_value', 'min_order_amount', 'max_discount'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  return values;
};

module.exports = Coupon;
