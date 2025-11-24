const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Order = require('../models/Order');
const OrderItem = require('../models/OrderItem');
const MenuItem = require('../models/MenuItem');
const Restaurant = require('../models/Restaurant');
const CustomerAddress = require('../models/CustomerAddress');
const Driver = require('../models/Driver');

/**
 * Get available orders (ready for pickup)
 * GET /api/driver/available-orders
 */
exports.getAvailableOrders = async (req, res) => {
  try {
    const orders = await Order.findAll({
      where: {
        status: 'ready',
        driver_id: null,
      },
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'phone', 'latitude', 'longitude'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
        {
          model: OrderItem,
          as: 'items',
        },
      ],
      order: [['created_at', 'ASC']],
    });

    res.json({
      orders,
      total: orders.length,
    });
  } catch (error) {
    console.error('Get available orders error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get driver's assigned orders
 * GET /api/driver/orders?status=picked_up
 */
exports.getDriverOrders = async (req, res) => {
  try {
    const driver_id = req.user.id;
    const { status } = req.query;

    const where = { driver_id };
    if (status) {
      where.status = status;
    }

    const orders = await Order.findAll({
      where,
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'phone', 'latitude', 'longitude'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
        {
          model: OrderItem,
          as: 'items',
        },
      ],
      order: [['created_at', 'DESC']],
    });

    res.json({
      orders,
      total: orders.length,
    });
  } catch (error) {
    console.error('Get driver orders error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Accept delivery
 * POST /api/driver/orders/:id/accept
 */
exports.acceptDelivery = async (req, res) => {
  try {
    const { id } = req.params;
    const driver_id = req.user.id;

    const order = await Order.findOne({
      where: { id, status: 'ready', driver_id: null },
    });

    if (!order) {
      return res.status(404).json({
        error: 'Order not found or already assigned',
      });
    }

    await order.update({
      driver_id,
      status: 'picked_up',
      picked_up_at: new Date(),
    });

    res.json({
      message: 'Delivery accepted successfully',
      order,
    });
  } catch (error) {
    console.error('Accept delivery error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update delivery status
 * PATCH /api/driver/orders/:id/status
 */
exports.updateDeliveryStatus = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const driver_id = req.user.id;
    const { status } = req.body;

    const order = await Order.findOne({
      where: { id, driver_id },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Validate status transition
    const validTransitions = {
      picked_up: ['delivering'],
      delivering: ['delivered'],
    };

    if (!validTransitions[order.status] ||
        !validTransitions[order.status].includes(status)) {
      return res.status(400).json({
        error: `Cannot transition from ${order.status} to ${status}`,
      });
    }

    const updateData = { status };
    if (status === 'delivered') {
      updateData.delivered_at = new Date();
    }

    await order.update(updateData);

    res.json({
      message: 'Delivery status updated successfully',
      order,
    });
  } catch (error) {
    console.error('Update delivery status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update driver location
 * PATCH /api/driver/location
 */
exports.updateLocation = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const driver_id = req.user.id;
    const { latitude, longitude } = req.body;

    const driver = await Driver.findByPk(driver_id);
    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    await driver.update({
      current_latitude: latitude,
      current_longitude: longitude,
    });

    res.json({
      message: 'Location updated successfully',
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Toggle online status
 * PATCH /api/driver/online
 */
exports.toggleOnlineStatus = async (req, res) => {
  try {
    const driver_id = req.user.id;
    const { is_online } = req.body;

    const driver = await Driver.findByPk(driver_id);
    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    await driver.update({ is_online });

    res.json({
      message: `Driver is now ${is_online ? 'online' : 'offline'}`,
      is_online,
    });
  } catch (error) {
    console.error('Toggle online status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get driver statistics
 * GET /api/driver/stats?period=today
 */
exports.getDriverStats = async (req, res) => {
  try {
    const driver_id = req.user.id;
    const { period = 'today' } = req.query;

    let startDate;
    const endDate = new Date();

    switch (period) {
      case 'today':
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'week':
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      default:
        startDate = new Date();
        startDate.setHours(0, 0, 0, 0);
    }

    const deliveredOrders = await Order.findAll({
      where: {
        driver_id,
        status: 'delivered',
        delivered_at: {
          [Op.between]: [startDate, endDate],
        },
      },
    });

    const totalDeliveries = deliveredOrders.length;
    const totalEarnings = deliveredOrders.reduce(
      (sum, order) => sum + parseFloat(order.delivery_fee),
      0
    );
    const averageEarning = totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0;

    res.json({
      period,
      total_deliveries: totalDeliveries,
      total_earnings: totalEarnings,
      average_earning: averageEarning,
    });
  } catch (error) {
    console.error('Get driver stats error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
