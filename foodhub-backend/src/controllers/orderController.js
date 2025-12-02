const { validationResult } = require('express-validator');
const sequelize = require('../config/database');
const stripe = require('../config/stripe');
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
  // Use Japan timezone (UTC+9)
  const now = new Date();
  const jstOffset = 9 * 60 * 60 * 1000; // 9 hours in milliseconds
  const jstDate = new Date(now.getTime() + jstOffset);

  const year = jstDate.getUTCFullYear();
  const month = String(jstDate.getUTCMonth() + 1).padStart(2, '0');
  const day = String(jstDate.getUTCDate()).padStart(2, '0');
  const dateStr = `${year}${month}${day}`;

  // Count today's orders (JST-based)
  const todayStartJST = `${year}-${month}-${day} 00:00:00`;
  const todayEndJST = `${year}-${month}-${day} 23:59:59`;

  const count = await Order.count({
    where: {
      created_at: {
        [sequelize.Sequelize.Op.between]: [todayStartJST, todayEndJST],
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

    // Service fee (15% of subtotal)
    const SERVICE_FEE_RATE = 0.15;
    const service_fee = Math.round(subtotal * SERVICE_FEE_RATE * 100) / 100;

    // Subtotal before tax
    const subtotal_before_tax = subtotal + delivery_fee + service_fee;

    // Tax (10%)
    const tax = Math.round(subtotal_before_tax * 0.1 * 100) / 100;

    // Total
    const total = subtotal_before_tax + tax;

    // Restaurant commission rate (from restaurant settings or default 35%)
    const restaurant_commission_rate = parseFloat(restaurant.commission_rate || 0.35);

    // Restaurant payout (subtotal after commission)
    const restaurant_payout = Math.round(subtotal * (1 - restaurant_commission_rate) * 100) / 100;

    // Driver payout (delivery fee or base rate)
    const driver_payout = delivery_fee;

    // Platform revenue
    const platform_revenue = Math.round(
      ((subtotal - restaurant_payout) +  // Restaurant commission
       (delivery_fee - driver_payout) +  // Delivery fee margin (0 if full amount to driver)
       service_fee +                     // Service fee
       tax) * 100                        // Tax
    ) / 100;

    console.log('[ORDER] Price breakdown:', {
      subtotal,
      delivery_fee,
      service_fee,
      tax,
      total,
      restaurant_commission_rate,
      restaurant_payout,
      driver_payout,
      platform_revenue,
    });

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
      service_fee,
      tax,
      discount: 0,
      total,
      payment_method,
      restaurant_commission_rate,
      restaurant_payout,
      driver_payout,
      platform_revenue,
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

    // Refund customer if paid by card
    if (order.payment_method === 'card' && order.stripe_payment_id) {
      const stripe = require('../config/stripe');
      try {
        // Check Payment Intent status first
        const paymentIntent = await stripe.paymentIntents.retrieve(order.stripe_payment_id);

        if (paymentIntent.status === 'succeeded') {
          // Payment completed - create refund
          const refund = await stripe.refunds.create({
            payment_intent: order.stripe_payment_id,
          });
          console.log(`[REFUND] Customer cancelled order ${order.id}, refund created: ${refund.id}`);
        } else if (paymentIntent.status === 'requires_payment_method' ||
                   paymentIntent.status === 'requires_confirmation') {
          // Payment not completed - cancel
          await stripe.paymentIntents.cancel(order.stripe_payment_id);
          console.log(`[REFUND] Customer cancelled order ${order.id}, payment cancelled: ${order.stripe_payment_id}`);
        } else {
          console.log(`[REFUND] Payment Intent status is ${paymentIntent.status}, no action needed`);
        }
      } catch (error) {
        console.error('[REFUND] Failed to process refund:', error);
        // Continue even if refund fails - can be processed manually later
      }
    }

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

    // Determine if driver is currently delivering to this customer
    // Use 'delivering' status for accurate detection (only one order can be 'delivering' at a time)
    const isCurrentlyDeliveringToMe = (order.status === 'delivering');

    // Calculate remaining deliveries before this order
    // Count orders with 'delivering' status that come before this order
    const deliveringOrders = driverOrders.filter(o => o.status === 'delivering');
    const remainingDeliveries = isCurrentlyDeliveringToMe ? 0 : deliveringOrders.length;

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

/**
 * Create Stripe Payment Intent for order
 * POST /api/orders/:id/create-payment-intent
 */
exports.createPaymentIntent = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const order = await Order.findOne({
      where: { id, customer_id },
      include: ['restaurant'],
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.payment_method !== 'card') {
      return res.status(400).json({
        error: 'Payment method must be card',
      });
    }

    if (order.stripe_payment_id) {
      // Payment Intent already exists
      const existingIntent = await stripe.paymentIntents.retrieve(order.stripe_payment_id);
      return res.json({
        client_secret: existingIntent.client_secret,
        payment_id: existingIntent.id,
      });
    }

    // Create Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(order.total),  // JPY is zero-decimal currency (no cents)
      currency: 'jpy',
      payment_method_types: ['card'],
      transfer_group: order.order_number,
      metadata: {
        order_id: order.id,
        customer_id: order.customer_id,
        restaurant_id: order.restaurant_id,
        order_number: order.order_number,
      },
      description: `FoodHub Order ${order.order_number}`,
    });

    // Save Payment Intent ID
    await order.update({
      stripe_payment_id: paymentIntent.id,
    });

    console.log(`[STRIPE] Payment Intent created: ${paymentIntent.id} for order ${order.id}`);

    res.json({
      client_secret: paymentIntent.client_secret,
      payment_id: paymentIntent.id,
      amount: order.total,
    });
  } catch (error) {
    console.error('Create payment intent error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
};

/**
 * Process payouts to restaurant and driver (called after delivery completion)
 * Internal function - not exposed as API endpoint
 */
async function processOrderPayouts(orderId) {
  try {
    const order = await Order.findByPk(orderId, {
      include: ['restaurant', 'driver'],
    });

    if (!order) {
      throw new Error(`Order ${orderId} not found`);
    }

    // Check if already processed
    if (order.payout_completed) {
      console.log(`[PAYOUT] Already completed for order ${orderId}`);
      return;
    }

    if (!order.stripe_payment_id) {
      throw new Error(`No Stripe payment ID for order ${orderId}`);
    }

    if (order.payment_method !== 'card') {
      console.log(`[PAYOUT] Skip for cash payment: order ${orderId}`);
      return;
    }

    console.log(`[PAYOUT] Processing payouts for order ${orderId}`);

    // Transfer to restaurant
    if (order.restaurant?.stripe_account_id) {
      // Calculate restaurant payout
      const commission_rate = parseFloat(order.restaurant.commission_rate || 0.35);
      const restaurant_payout = Math.round(order.subtotal * (1 - commission_rate) * 100) / 100;

      if (restaurant_payout > 0) {
        const restaurantTransfer = await stripe.transfers.create({
          amount: Math.round(restaurant_payout),  // JPY is zero-decimal currency
          currency: 'jpy',
          destination: order.restaurant.stripe_account_id,
          transfer_group: order.order_number,
          metadata: {
            order_id: order.id,
            type: 'restaurant_payout',
            original_subtotal: order.subtotal,
            commission_rate: commission_rate,
          },
          description: `Order ${order.order_number} - Restaurant payout`,
        });

        console.log(`[PAYOUT] Restaurant transfer: ${restaurantTransfer.id}`);

        // Update order
        await order.update({
          stripe_restaurant_transfer_id: restaurantTransfer.id,
        });
      }
    } else {
      console.warn(`[PAYOUT] Restaurant ${order.restaurant_id} has no Stripe account`);
    }

    // Transfer to driver
    if (order.driver?.stripe_account_id) {
      const driver_payout = parseFloat(order.driver.base_payout_per_delivery || order.delivery_fee);

      if (driver_payout > 0) {
        const driverTransfer = await stripe.transfers.create({
          amount: Math.round(driver_payout),  // JPY is zero-decimal currency
          currency: 'jpy',
          destination: order.driver.stripe_account_id,
          transfer_group: order.order_number,
          metadata: {
            order_id: order.id,
            type: 'driver_payout',
            delivery_fee: order.delivery_fee,
          },
          description: `Order ${order.order_number} - Driver payout`,
        });

        console.log(`[PAYOUT] Driver transfer: ${driverTransfer.id}`);

        // Update order
        await order.update({
          stripe_driver_transfer_id: driverTransfer.id,
        });
      }
    } else {
      console.warn(`[PAYOUT] Driver ${order.driver_id} has no Stripe account`);
    }

    // Mark as completed
    await order.update({
      payout_completed: true,
    });

    console.log(`[PAYOUT] Completed for order ${orderId}`);
  } catch (error) {
    console.error(`[PAYOUT] Error for order ${orderId}:`, error);
    throw error;
  }
}

// Export for use in other controllers
exports.processOrderPayouts = processOrderPayouts;
