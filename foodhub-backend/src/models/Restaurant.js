const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Restaurant = sequelize.define('Restaurant', {
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
  name: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  category: {
    type: DataTypes.STRING(50),
    allowNull: false,
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  address: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: false,
  },
  longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: false,
  },
  cover_image_url: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  logo_url: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  rating: {
    type: DataTypes.DECIMAL(3, 2),
    defaultValue: 0.00,
  },
  total_reviews: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  min_order_amount: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
  },
  delivery_fee: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
  },
  delivery_time_minutes: {
    type: DataTypes.INTEGER,
    defaultValue: 30,
  },
  delivery_radius_km: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 5.00,
  },
  is_open: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  is_approved: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  stripe_account_id: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  stripe_onboarding_completed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  stripe_charges_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  stripe_payouts_enabled: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  commission_rate: {
    type: DataTypes.DECIMAL(5, 4),
    defaultValue: 0.35,
  },
}, {
  tableName: 'restaurants',
  timestamps: true,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
Restaurant.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['latitude', 'longitude', 'rating', 'min_order_amount',
                         'delivery_fee', 'delivery_radius_km', 'commission_rate'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  return values;
};

module.exports = Restaurant;
