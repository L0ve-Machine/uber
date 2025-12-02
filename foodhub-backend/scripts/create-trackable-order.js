require('dotenv').config();
const sequelize = require('../src/config/database');

async function createTrackableOrder() {
  try {
    console.log('🗺️  Creating a trackable order with map coordinates...');

    // Create an order with status 'picked_up' so the map will show
    const [results] = await sequelize.query(`
      INSERT INTO orders (
        order_number,
        customer_id,
        restaurant_id,
        driver_id,
        delivery_address_id,
        status,
        subtotal,
        delivery_fee,
        tax,
        discount,
        total,
        payment_method,
        created_at,
        updated_at,
        accepted_at,
        picked_up_at
      )
      SELECT
        CONCAT('TEST-MAP-', FLOOR(RAND() * 10000)),
        1,  -- customer_id
        1,  -- restaurant_id
        1,  -- driver_id (assigned)
        1,  -- delivery_address_id
        'picked_up',  -- status (so map shows)
        1280.00,
        300.00,
        177.20,
        0.00,
        1757.20,
        'credit_card',
        NOW(),
        NOW(),
        NOW(),
        NOW()
      WHERE EXISTS (SELECT 1 FROM customers WHERE id = 1)
        AND EXISTS (SELECT 1 FROM restaurants WHERE id = 1)
        AND EXISTS (SELECT 1 FROM drivers WHERE id = 1)
        AND EXISTS (SELECT 1 FROM customer_addresses WHERE id = 1)
    `);

    // Get the order ID
    const [orderResult] = await sequelize.query(`
      SELECT id, order_number FROM orders
      WHERE order_number LIKE 'TEST-MAP-%'
      ORDER BY id DESC
      LIMIT 1
    `);

    if (orderResult.length > 0) {
      const orderId = orderResult[0].id;
      const orderNumber = orderResult[0].order_number;

      // Add order items
      await sequelize.query(`
        INSERT INTO order_items (
          order_id,
          menu_item_id,
          quantity,
          unit_price,
          total_price,
          selected_options,
          special_request
        )
        VALUES (${orderId}, 3, 2, 640, 1280, NULL, NULL)
      `);

      console.log('✅ Trackable order created successfully!');
      console.log(`📋 Order Number: ${orderNumber}`);
      console.log(`🆔 Order ID: ${orderId}`);
      console.log(`📱 Status: picked_up (配達中)`);
      console.log('');
      console.log('🗺️  To view the tracking map:');
      console.log('   1. Log in as customer (customer@test.com)');
      console.log('   2. Go to 注文履歴 (Order History)');
      console.log(`   3. Tap on order #${orderNumber}`);
      console.log('   4. Scroll down to see the 配達状況 map');
      console.log('');
      console.log('📍 Map will show:');
      console.log('   🍽️  Restaurant location (orange marker)');
      console.log('   🏠 Delivery address (blue marker)');
      console.log('   🛵 Driver location (green marker - if real-time data available)');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

createTrackableOrder();
