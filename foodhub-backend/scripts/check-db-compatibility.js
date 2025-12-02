require('dotenv').config();
const mysql = require('mysql2/promise');

async function checkDatabaseCompatibility() {
  console.log('🔍 Checking database compatibility...\n');

  try {
    // Try to connect using .env credentials
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'foodhub',
    });

    console.log('✅ Database connection successful!\n');
    console.log(`📊 Connected to: ${process.env.DB_NAME} at ${process.env.DB_HOST}\n`);

    // Check orders table structure
    console.log('📋 Checking orders table...');
    const [ordersColumns] = await connection.query('DESCRIBE orders');
    const ordersFields = ordersColumns.map(col => col.Field);

    const requiredOrderFields = [
      'id', 'order_number', 'customer_id', 'restaurant_id', 'driver_id',
      'delivery_address_id', 'status', 'subtotal', 'delivery_fee', 'tax',
      'total', 'payment_method', 'created_at', 'accepted_at', 'picked_up_at', 'delivered_at'
    ];

    let ordersMissing = [];
    for (const field of requiredOrderFields) {
      if (!ordersFields.includes(field)) {
        ordersMissing.push(field);
      }
    }

    if (ordersMissing.length === 0) {
      console.log('✅ Orders table has all required fields');
    } else {
      console.log('❌ Orders table missing fields:', ordersMissing);
    }

    // Check order_items table structure
    console.log('\n📋 Checking order_items table...');
    const [itemsColumns] = await connection.query('DESCRIBE order_items');
    const itemsFields = itemsColumns.map(col => col.Field);

    const requiredItemFields = [
      'id', 'order_id', 'menu_item_id', 'quantity', 'unit_price', 'total_price'
    ];

    let itemsMissing = [];
    for (const field of requiredItemFields) {
      if (!itemsFields.includes(field)) {
        itemsMissing.push(field);
      }
    }

    if (itemsMissing.length === 0) {
      console.log('✅ Order_items table has all required fields');
    } else {
      console.log('❌ Order_items table missing fields:', itemsMissing);
    }

    // Check existing data
    console.log('\n📊 Checking existing data...');
    const [customers] = await connection.query('SELECT COUNT(*) as count FROM customers');
    const [restaurants] = await connection.query('SELECT COUNT(*) as count FROM restaurants');
    const [drivers] = await connection.query('SELECT COUNT(*) as count FROM drivers');
    const [menuItems] = await connection.query('SELECT COUNT(*) as count FROM menu_items');
    const [addresses] = await connection.query('SELECT COUNT(*) as count FROM customer_addresses');
    const [orders] = await connection.query('SELECT COUNT(*) as count FROM orders');

    console.log(`  Customers: ${customers[0].count}`);
    console.log(`  Restaurants: ${restaurants[0].count}`);
    console.log(`  Drivers: ${drivers[0].count}`);
    console.log(`  Menu Items: ${menuItems[0].count}`);
    console.log(`  Addresses: ${addresses[0].count}`);
    console.log(`  Existing Orders: ${orders[0].count}`);

    // Validate we have minimum data
    const hasRequiredData =
      customers[0].count > 0 &&
      restaurants[0].count > 0 &&
      menuItems[0].count > 0 &&
      addresses[0].count > 0;

    console.log('\n' + '='.repeat(50));
    if (ordersMissing.length === 0 && itemsMissing.length === 0 && hasRequiredData) {
      console.log('✅ DATABASE IS COMPATIBLE!');
      console.log('\nYou can safely run: node scripts/add-test-orders.js');
    } else {
      console.log('❌ DATABASE COMPATIBILITY ISSUES FOUND!');
      if (!hasRequiredData) {
        console.log('\n⚠️  You need to run: node scripts/seed-sample-data.js first');
      }
      if (ordersMissing.length > 0 || itemsMissing.length > 0) {
        console.log('\n⚠️  Database schema is missing required fields');
      }
    }
    console.log('='.repeat(50) + '\n');

    await connection.end();

  } catch (error) {
    console.error('❌ Database connection error:', error.message);
    console.log('\n⚠️  Check your .env file database credentials:');
    console.log(`  DB_HOST=${process.env.DB_HOST}`);
    console.log(`  DB_USER=${process.env.DB_USER}`);
    console.log(`  DB_NAME=${process.env.DB_NAME}`);
  }
}

checkDatabaseCompatibility();
