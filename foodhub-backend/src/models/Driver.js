const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Driver = sequelize.define('Driver', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  email: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  password_hash: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  full_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  vehicle_type: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  license_number: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  profile_image_url: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  is_online: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  is_approved: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  current_latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true,
  },
  current_longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true,
  },
  rating: {
    type: DataTypes.DECIMAL(3, 2),
    defaultValue: 0.00,
  },
  total_deliveries: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  bank_account_info: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  stripe_account_id: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  stripe_onboarding_completed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  stripe_payouts_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  base_payout_per_delivery: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 400.00,
  },
}, {
  tableName: 'drivers',
  timestamps: true,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
Driver.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['current_latitude', 'current_longitude', 'rating', 'base_payout_per_delivery'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  return values;
};

module.exports = Driver;
