const { validationResult } = require('express-validator');
const sequelize = require('../config/database');
const Order = require('../models/Order');
const OrderItem = require('../models/OrderItem');
const Restaurant = require('../models/Restaurant');
const CustomerAddress = require('../models/CustomerAddress');
const MenuItem = require('../models/MenuItem');
const Driver = require('../models/Driver');

/**
 * Generate unique order number
 * Format: ORD-YYYYMMDD-XXXX
 */
const generateOrderNumber = async () => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');

  // Count today's orders
  const todayStart = new Date(today.setHours(0, 0, 0, 0));
  const todayEnd = new Date(today.setHours(23, 59, 59, 999));

  const count = await Order.count({
    where: {
      created_at: {
        [sequelize.Sequelize.Op.between]: [todayStart, todayEnd],
      },
    },
  });

  const orderNum = (count + 1).toString().padStart(4, '0');
  return `ORD-${dateStr}-${orderNum}`;
};

/**
 * Create new order
 * POST /api/orders
 */
exports.createOrder = async (req, res) => {
  const transaction = await sequelize.transaction();

  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await transaction.rollback();
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      restaurant_id,
      delivery_address_id,
      items, // [{ menu_item_id, quantity, selected_options, special_request }]
      payment_method,
      special_instructions,
      scheduled_at,
    } = req.body;

    const customer_id = req.user.id;

    // Validate restaurant exists
    const restaurant = await Restaurant.findByPk(restaurant_id);
    if (!restaurant) {
      await transaction.rollback();
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Validate delivery address belongs to customer
    const address = await CustomerAddress.findOne({
      where: { id: delivery_address_id, customer_id },
    });
    if (!address) {
      await transaction.rollback();
      return res.status(404).json({ error: 'Delivery address not found' });
    }

    // Calculate order totals
    let subtotal = 0;
    const orderItemsData = [];

    for (const item of items) {
      const menuItem = await MenuItem.findByPk(item.menu_item_id);
      if (!menuItem || menuItem.restaurant_id !== restaurant_id) {
        await transaction.rollback();
        return res.status(400).json({
          error: `Invalid menu item: ${item.menu_item_id}`
        });
      }

      if (!menuItem.is_available) {
        await transaction.rollback();
        return res.status(400).json({
          error: `Menu item not available: ${menuItem.name}`
        });
      }

      // Calculate item total (base price + options)
      let itemTotal = parseFloat(menuItem.price) * item.quantity;

      if (item.selected_options && item.selected_options.length > 0) {
        const optionsTotal = item.selected_options.reduce((sum, opt) => {
          return sum + (parseFloat(opt.price || 0) * item.quantity);
        }, 0);
        itemTotal += optionsTotal;
      }

      subtotal += itemTotal;

      orderItemsData.push({
        menu_item_id: item.menu_item_id,
        quantity: item.quantity,
        unit_price: menuItem.price,
        total_price: itemTotal,
        selected_options: item.selected_options || null,
        special_request: item.special_request || null,
      });
    }

    // Calculate fees and total
    const delivery_fee = parseFloat(restaurant.delivery_fee);
    const tax = subtotal * 0.1; // 10% tax
    const total = subtotal + delivery_fee + tax;

    // Generate order number
    const order_number = await generateOrderNumber();

    // Create order
    const order = await Order.create({
      order_number,
      customer_id,
      restaurant_id,
      delivery_address_id,
      status: 'pending',
      subtotal,
      delivery_fee,
      tax,
      discount: 0,
      total,
      payment_method,
      special_instructions,
      scheduled_at: scheduled_at || null,
    }, { transaction });

    // Create order items
    for (const itemData of orderItemsData) {
      await OrderItem.create({
        order_id: order.id,
        ...itemData,
      }, { transaction });
    }

    await transaction.commit();

    // Fetch complete order with associations
    const completeOrder = await Order.findByPk(order.id, {
      include: [
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
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'phone', 'address'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
      ],
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: completeOrder,
    });
  } catch (error) {
    await transaction.rollback();
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get customer's orders
 * GET /api/orders
 */
exports.getCustomerOrders = async (req, res) => {
  try {
    const customer_id = req.user.id;
    const { status } = req.query;

    const where = { customer_id };
    if (status) {
      where.status = status;
    }

    const orders = await Order.findAll({
      where,
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'logo_url'],
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
    console.error('Get customer orders error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get order by ID
 * GET /api/orders/:id
 */
exports.getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const order = await Order.findOne({
      where: { id, customer_id },
      include: [
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
        {
          model: Restaurant,
          as: 'restaurant',
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
        },
      ],
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    console.error('Get order by ID error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Cancel order
 * PATCH /api/orders/:id/cancel
 */
exports.cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const order = await Order.findOne({
      where: { id, customer_id },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Only pending orders can be cancelled
    if (order.status !== 'pending') {
      return res.status(400).json({
        error: 'Only pending orders can be cancelled'
      });
    }

    await order.update({
      status: 'cancelled',
      cancelled_at: new Date(),
    });

    res.json({
      message: 'Order cancelled successfully',
      order,
    });
  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get order tracking information (with privacy protection)
 * GET /api/orders/:id/tracking
 */
exports.getOrderTracking = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    // Get order with all necessary relations
    const order = await Order.findOne({
      where: { id, customer_id },
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'address', 'latitude', 'longitude', 'phone'],
        },
        {
          model: CustomerAddress,
          as: 'delivery_address',
          attributes: ['id', 'address_line', 'city', 'latitude', 'longitude'],
        },
        {
          model: Driver,
          as: 'driver',
          attributes: ['id', 'full_name', 'phone', 'current_latitude', 'current_longitude', 'updated_at'],
        },
      ],
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // If no driver assigned yet
    if (!order.driver_id) {
      return res.json({
        orderId: order.id,
        orderNumber: order.order_number,
        status: order.status,
        isDriverAssigned: false,
        message: '配達員を探しています...',
        restaurantLocation: order.restaurant ? {
          latitude: order.restaurant.latitude,
          longitude: order.restaurant.longitude,
          name: order.restaurant.name,
          address: order.restaurant.address,
        } : null,
        deliveryLocation: order.delivery_address ? {
          latitude: order.delivery_address.latitude,
          longitude: order.delivery_address.longitude,
          address: order.delivery_address.address_line + ', ' + order.delivery_address.city,
        } : null,
      });
    }

    // Get all active orders for this driver (for sequence calculation)
    const driverOrders = await Order.findAll({
      where: {
        driver_id: order.driver_id,
        status: ['picked_up', 'delivering'],
      },
      attributes: ['id', 'created_at', 'delivery_sequence'],
      order: [
        ['delivery_sequence', 'ASC'],
        ['created_at', 'ASC'],
      ],
    });

    // Find position of this order in driver's queue
    const myIndex = driverOrders.findIndex(o => o.id === order.id);
    const isCurrentlyDeliveringToMe = myIndex === 0;  // First in queue = currently delivering
    const remainingDeliveries = Math.max(0, myIndex);  // How many before me

    // *** PRIVACY PROTECTION: Only show driver location if delivering to current customer ***
    const driverLocation = (isCurrentlyDeliveringToMe && order.driver) ? {
      latitude: parseFloat(order.driver.current_latitude),
      longitude: parseFloat(order.driver.current_longitude),
      lastUpdate: order.driver.updated_at,
    } : null;

    // Calculate driver info (name & phone shown only when actively delivering)
    const driverInfo = order.driver ? {
      id: order.driver.id,
      fullName: isCurrentlyDeliveringToMe ? order.driver.full_name : null,
      phone: isCurrentlyDeliveringToMe ? order.driver.phone : null,
    } : null;

    res.json({
      orderId: order.id,
      orderNumber: order.order_number,
      status: order.status,
      isDriverAssigned: true,
      isCurrentlyDeliveringToYou: isCurrentlyDeliveringToMe,
      deliverySequence: myIndex + 1,
      remainingDeliveries,
      totalOrdersInBatch: driverOrders.length,

      // Driver location (null if not currently delivering to you)
      driverLocation,
      driverInfo,

      // Location data
      restaurantLocation: order.restaurant ? {
        latitude: order.restaurant.latitude,
        longitude: order.restaurant.longitude,
        name: order.restaurant.name,
        address: order.restaurant.address,
      } : null,

      deliveryLocation: order.delivery_address ? {
        latitude: order.delivery_address.latitude,
        longitude: order.delivery_address.longitude,
        address: order.delivery_address.address_line + ', ' + order.delivery_address.city,
      } : null,

      // Timestamps
      createdAt: order.created_at,
      acceptedAt: order.accepted_at,
      pickedUpAt: order.picked_up_at,
      estimatedDelivery: order.estimated_delivery_time,
    });
  } catch (error) {
    console.error('Get order tracking error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
