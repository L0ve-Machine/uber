const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Favorite = sequelize.define('Favorite', {
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
  restaurant_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'restaurants',
      key: 'id',
    },
  },
}, {
  tableName: 'favorites',
  timestamps: true,
  underscored: true,
  updatedAt: false, // Only has created_at
  indexes: [
    {
      unique: true,
      fields: ['customer_id', 'restaurant_id'],
    },
  ],
});

module.exports = Favorite;
