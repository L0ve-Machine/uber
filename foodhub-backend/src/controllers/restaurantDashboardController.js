const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Order = require('../models/Order');
const OrderItem = require('../models/OrderItem');
const MenuItem = require('../models/MenuItem');
const MenuItemOption = require('../models/MenuItemOption');
const Customer = require('../models/Customer');
const CustomerAddress = require('../models/CustomerAddress');

/**
 * Get restaurant's orders
 * GET /api/restaurant/orders?status=pending
 */
exports.getRestaurantOrders = async (req, res) => {
  try {
    const restaurant_id = req.user.id;
    const { status } = req.query;

    const where = { restaurant_id };
    if (status) {
      where.status = status;
    }

    const orders = await Order.findAll({
      where,
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'full_name', 'phone'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
        {
          model: OrderItem,
          as: 'items',
          include: [
            {
              model: MenuItem,
              as: 'menu_item',
            },
          ],
        },
      ],
      order: [
        ['created_at', 'DESC'],
      ],
    });

    res.json({
      orders,
      total: orders.length,
    });
  } catch (error) {
    console.error('Get restaurant orders error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get order detail
 * GET /api/restaurant/orders/:id
 */
exports.getRestaurantOrderDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant_id = req.user.id;

    const order = await Order.findOne({
      where: { id, restaurant_id },
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'full_name', 'phone'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
        {
          model: OrderItem,
          as: 'items',
          include: [
            {
              model: MenuItem,
              as: 'menu_item',
            },
          ],
        },
      ],
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    console.error('Get restaurant order detail error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Accept order
 * PATCH /api/restaurant/orders/:id/accept
 */
exports.acceptOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant_id = req.user.id;

    const order = await Order.findOne({
      where: { id, restaurant_id },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({
        error: 'Only pending orders can be accepted',
      });
    }

    await order.update({
      status: 'accepted',
      accepted_at: new Date(),
    });

    res.json({
      message: 'Order accepted successfully',
      order,
    });
  } catch (error) {
    console.error('Accept order error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Reject order
 * PATCH /api/restaurant/orders/:id/reject
 */
exports.rejectOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant_id = req.user.id;
    const { reason } = req.body;

    const order = await Order.findOne({
      where: { id, restaurant_id },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.status !== 'pending') {
      return res.status(400).json({
        error: 'Only pending orders can be rejected',
      });
    }

    await order.update({
      status: 'cancelled',
      cancelled_at: new Date(),
      special_instructions: reason || order.special_instructions,
    });

    res.json({
      message: 'Order rejected successfully',
      order,
    });
  } catch (error) {
    console.error('Reject order error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update order status
 * PATCH /api/restaurant/orders/:id/status
 */
exports.updateOrderStatus = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const restaurant_id = req.user.id;
    const { status } = req.body;

    const order = await Order.findOne({
      where: { id, restaurant_id },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Validate status transition
    const validTransitions = {
      accepted: ['preparing'],
      preparing: ['ready'],
      ready: ['picked_up'], // Driver will update this
    };

    if (!validTransitions[order.status] ||
        !validTransitions[order.status].includes(status)) {
      return res.status(400).json({
        error: `Cannot transition from ${order.status} to ${status}`,
      });
    }

    await order.update({ status });

    res.json({
      message: 'Order status updated successfully',
      order,
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get restaurant statistics
 * GET /api/restaurant/stats?period=today
 */
exports.getRestaurantStats = async (req, res) => {
  try {
    const restaurant_id = req.user.id;
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

    const orders = await Order.findAll({
      where: {
        restaurant_id,
        created_at: {
          [Op.between]: [startDate, endDate],
        },
        status: {
          [Op.notIn]: ['cancelled'],
        },
      },
    });

    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + parseFloat(order.total), 0);
    const averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    const statusCounts = {};
    orders.forEach((order) => {
      statusCounts[order.status] = (statusCounts[order.status] || 0) + 1;
    });

    res.json({
      period,
      total_orders: totalOrders,
      total_revenue: totalRevenue,
      average_order_value: averageOrderValue,
      status_counts: statusCounts,
    });
  } catch (error) {
    console.error('Get restaurant stats error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
