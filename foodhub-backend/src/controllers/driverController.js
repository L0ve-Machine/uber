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

    // Process payouts when delivery is completed
    if (status === 'delivered' && order.payment_method === 'card') {
      const { processOrderPayouts } = require('./orderController');
      try {
        await processOrderPayouts(order.id);
        console.log(`[DELIVERY] Payouts processed for order ${order.id}`);
      } catch (error) {
        console.error('[DELIVERY] Payout failed:', error);
        // Continue even if payout fails - can be processed manually later
      }
    }

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

/**
 * Get driver profile (with Stripe status)
 * GET /api/driver/profile
 */
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const driver = await Driver.findOne({
      where: { id: userId },
      attributes: {
        exclude: ['password_hash'],
      },
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    res.json({
      id: driver.id,
      email: driver.email,
      full_name: driver.full_name,
      phone: driver.phone,
      vehicle_type: driver.vehicle_type,
      license_number: driver.license_number,
      is_online: driver.is_online,
      is_approved: driver.is_approved,
      current_latitude: driver.current_latitude,
      current_longitude: driver.current_longitude,
      stripe_account_id: driver.stripe_account_id,
      stripe_onboarding_completed: driver.stripe_onboarding_completed,
      stripe_payouts_enabled: driver.stripe_payouts_enabled,
      base_payout_per_delivery: driver.base_payout_per_delivery,
      created_at: driver.created_at,
      updated_at: driver.updated_at,
    });
  } catch (error) {
    console.error('Get driver profile error:', error);
    res.status(500).json({ error: 'Failed to get driver profile' });
  }
};

/**
 * Verify pickup PIN
 * POST /api/driver/orders/:id/verify-pin
 */
exports.verifyPickupPin = async (req, res) => {
  try {
    const { id } = req.params;
    const driver_id = req.user.id;
    const { pin } = req.body;

    if (!pin || pin.length !== 4) {
      return res.status(400).json({ error: 'Invalid PIN format' });
    }

    const order = await Order.findOne({
      where: { id, driver_id, status: 'picked_up' },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // PIN照合
    if (order.pickup_pin !== pin) {
      console.log(`❌ Incorrect PIN for order ${order.order_number}: entered=${pin}, expected=${order.pickup_pin}`);
      return res.status(400).json({
        error: 'Incorrect PIN',
        message: 'ピックアップPINが正しくありません。レストランに確認してください。',
      });
    }

    // PIN確認成功
    await order.update({
      pin_verified_at: new Date(),
    });

    console.log(`✅ PIN verified for order ${order.order_number}`);

    res.json({
      message: 'PIN verified successfully',
      order,
    });
  } catch (error) {
    console.error('Verify pickup PIN error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
