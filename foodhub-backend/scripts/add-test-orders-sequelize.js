require('dotenv').config();
const { Sequelize, DataTypes } = require('sequelize');

// Use the same Sequelize configuration as the backend
const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: 'mysql',
    logging: false,
  }
);

async function addTestOrders() {
  try {
    console.log('🔄 Adding test orders and delivery data...\n');

    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully!\n');

    // Get existing data using raw queries
    const [customers] = await sequelize.query('SELECT id FROM customers LIMIT 1');
    const [restaurants] = await sequelize.query('SELECT id FROM restaurants LIMIT 1');
    const [drivers] = await sequelize.query('SELECT id FROM drivers LIMIT 1');
    const [menuItems] = await sequelize.query('SELECT id, name, price FROM menu_items LIMIT 5');
    const [addresses] = await sequelize.query('SELECT id FROM customer_addresses LIMIT 1');

    if (customers.length === 0 || restaurants.length === 0 || menuItems.length === 0 || addresses.length === 0) {
      console.log('❌ Missing required data. Please run seed-sample-data.js first.');
      return;
    }

    const customerId = customers[0].id;
    const restaurantId = restaurants[0].id;
    const driverId = drivers.length > 0 ? drivers[0].id : null;
    const addressId = addresses[0].id;

    console.log(`📊 Using: Customer ${customerId}, Restaurant ${restaurantId}, Driver ${driverId}, Address ${addressId}\n`);

    // Test orders with different statuses
    const testOrders = [
      // Active delivery - picked up, ready for delivering
      {
        orderNumber: `ORD-${Date.now()}-1`,
        status: 'picked_up',
        subtotal: 2500,
        deliveryFee: 300,
        tax: 250,
        total: 3050,
        items: [
          { menuItemId: menuItems[0].id, quantity: 2, unitPrice: 800 },
          { menuItemId: menuItems[1].id, quantity: 1, unitPrice: 900 },
        ],
        pickedUpAt: new Date(Date.now() - 10 * 60 * 1000), // 10 minutes ago
      },
      // Active delivery - currently delivering
      {
        orderNumber: `ORD-${Date.now()}-2`,
        status: 'delivering',
        subtotal: 1800,
        deliveryFee: 300,
        tax: 180,
        total: 2280,
        items: [
          { menuItemId: menuItems[0].id, quantity: 1, unitPrice: 800 },
          { menuItemId: menuItems[2].id, quantity: 2, unitPrice: 500 },
        ],
        pickedUpAt: new Date(Date.now() - 20 * 60 * 1000), // 20 minutes ago
      },
      // Completed delivery - delivered
      {
        orderNumber: `ORD-${Date.now()}-3`,
        status: 'delivered',
        subtotal: 3200,
        deliveryFee: 300,
        tax: 320,
        total: 3820,
        items: [
          { menuItemId: menuItems[0].id, quantity: 3, unitPrice: 800 },
          { menuItemId: menuItems[1].id, quantity: 2, unitPrice: 400 },
        ],
        pickedUpAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
        deliveredAt: new Date(Date.now() - 1.5 * 60 * 60 * 1000), // 1.5 hours ago
      },
      // Completed delivery - older
      {
        orderNumber: `ORD-${Date.now()}-4`,
        status: 'delivered',
        subtotal: 1500,
        deliveryFee: 300,
        tax: 150,
        total: 1950,
        items: [
          { menuItemId: menuItems[3].id, quantity: 2, unitPrice: 600 },
          { menuItemId: menuItems[4].id, quantity: 1, unitPrice: 300 },
        ],
        pickedUpAt: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
        deliveredAt: new Date(Date.now() - 23.5 * 60 * 60 * 1000), // 23.5 hours ago
      },
      // Available order - ready for pickup
      {
        orderNumber: `ORD-${Date.now()}-5`,
        status: 'ready',
        subtotal: 2800,
        deliveryFee: 300,
        tax: 280,
        total: 3380,
        items: [
          { menuItemId: menuItems[0].id, quantity: 2, unitPrice: 800 },
          { menuItemId: menuItems[1].id, quantity: 1, unitPrice: 1200 },
        ],
      },
      // Preparing order
      {
        orderNumber: `ORD-${Date.now()}-6`,
        status: 'preparing',
        subtotal: 2200,
        deliveryFee: 300,
        tax: 220,
        total: 2720,
        items: [
          { menuItemId: menuItems[2].id, quantity: 3, unitPrice: 600 },
          { menuItemId: menuItems[3].id, quantity: 1, unitPrice: 400 },
        ],
      },
      // Very old completed order
      {
        orderNumber: `ORD-${Date.now()}-7`,
        status: 'delivered',
        subtotal: 4500,
        deliveryFee: 300,
        tax: 450,
        total: 5250,
        items: [
          { menuItemId: menuItems[0].id, quantity: 4, unitPrice: 800 },
          { menuItemId: menuItems[1].id, quantity: 2, unitPrice: 650 },
        ],
        pickedUpAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
        deliveredAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000 + 30 * 60 * 1000), // 7 days ago + 30 min
      },
    ];

    let ordersCreated = 0;
    let orderItemsCreated = 0;

    for (const order of testOrders) {
      // Build the INSERT query
      const acceptedAt = order.status !== 'pending' ? 'NOW()' : 'NULL';
      const pickedUpVal = order.pickedUpAt ? `'${order.pickedUpAt.toISOString().slice(0, 19).replace('T', ' ')}'` : 'NULL';
      const deliveredVal = order.deliveredAt ? `'${order.deliveredAt.toISOString().slice(0, 19).replace('T', ' ')}'` : 'NULL';

      const insertOrderQuery = `
        INSERT INTO orders (
          order_number, customer_id, restaurant_id, driver_id, delivery_address_id,
          status, subtotal, delivery_fee, tax, total, payment_method,
          created_at, accepted_at, picked_up_at, delivered_at
        ) VALUES (
          '${order.orderNumber}', ${customerId}, ${restaurantId}, ${driverId}, ${addressId},
          '${order.status}', ${order.subtotal}, ${order.deliveryFee}, ${order.tax}, ${order.total}, 'card',
          NOW(), ${acceptedAt}, ${pickedUpVal}, ${deliveredVal}
        )
      `;

      const [result] = await sequelize.query(insertOrderQuery);
      const orderId = result;
      ordersCreated++;

      // Insert order items
      for (const item of order.items) {
        const totalPrice = item.quantity * item.unitPrice;
        await sequelize.query(`
          INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price, total_price)
          VALUES (${orderId}, ${item.menuItemId}, ${item.quantity}, ${item.unitPrice}, ${totalPrice})
        `);
        orderItemsCreated++;
      }

      console.log(`✅ Order ${order.orderNumber} (${order.status}) created with ${order.items.length} items`);
    }

    console.log(`\n✅ Successfully created ${ordersCreated} orders with ${orderItemsCreated} items total!\n`);
    console.log('📊 Order Status Breakdown:');
    console.log('  - picked_up: 1 (ready for driver to start delivering)');
    console.log('  - delivering: 1 (currently out for delivery)');
    console.log('  - delivered: 3 (completed deliveries for history)');
    console.log('  - ready: 1 (available for driver to accept)');
    console.log('  - preparing: 1 (restaurant is preparing)\n');

    console.log('🎉 Test orders added successfully! You can now:');
    console.log('  1. Login as driver (driver@test.com / password123)');
    console.log('  2. View active deliveries');
    console.log('  3. See completed delivery history');
    console.log('  4. Accept new orders\n');

  } catch (error) {
    console.error('❌ Error adding test orders:', error);
  } finally {
    await sequelize.close();
  }
}

// Run the script
addTestOrders();
