const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const CustomerAddress = sequelize.define('CustomerAddress', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  customer_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'customers',
      key: 'id',
    },
  },
  address_line: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  city: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  postal_code: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  latitude: {
    type: DataTypes.DECIMAL(10, 8),
    allowNull: true,
  },
  longitude: {
    type: DataTypes.DECIMAL(11, 8),
    allowNull: true,
  },
  is_default: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  label: {
    type: DataTypes.STRING(50),
    defaultValue: 'Home',
  },
}, {
  tableName: 'customer_addresses',
  timestamps: true,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
CustomerAddress.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  const decimalFields = ['latitude', 'longitude'];
  decimalFields.forEach(field => {
    if (values[field] !== null && values[field] !== undefined) {
      values[field] = parseFloat(values[field]);
    }
  });

  return values;
};

module.exports = CustomerAddress;
