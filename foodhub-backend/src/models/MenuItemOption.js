const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const MenuItemOption = sequelize.define('MenuItemOption', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  menu_item_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'menu_items',
      key: 'id',
    },
  },
  option_group_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  option_name: {
    type: DataTypes.STRING(100),
    allowNull: false,
  },
  additional_price: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
  },
}, {
  tableName: 'menu_item_options',
  timestamps: false,
  underscored: true,
});

// Override toJSON to convert DECIMAL strings to numbers
MenuItemOption.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());

  // Convert DECIMAL fields to numbers
  if (values.additional_price !== null && values.additional_price !== undefined) {
    values.additional_price = parseFloat(values.additional_price);
  }

  return values;
};

module.exports = MenuItemOption;
