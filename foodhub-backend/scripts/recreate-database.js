require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function recreateDatabase() {
  console.log('🔄 Recreating database with friend\'s schema...\n');

  try {
    // Connect to MySQL without selecting a database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL server\n');

    // Drop and recreate database
    console.log('🗑️  Dropping existing foodhub database...');
    await connection.query('DROP DATABASE IF EXISTS foodhub');
    console.log('✅ Database dropped\n');

    console.log('📦 Creating new foodhub database...');
    await connection.query('CREATE DATABASE foodhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    console.log('✅ Database created\n');

    // Switch to the new database
    await connection.query('USE foodhub');

    // Read schema file
    const schemaPath = path.join(__dirname, '..', 'database', 'schema.sql');
    console.log('📖 Reading schema from:', schemaPath);
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Remove the CREATE DATABASE and USE statements from schema
    const cleanedSchema = schema
      .replace(/CREATE DATABASE.*?;/gs, '')
      .replace(/USE foodhub;/g, '')
      .trim();

    console.log('📊 Executing schema...\n');
    await connection.query(cleanedSchema);

    console.log('✅ Schema loaded successfully!\n');

    // Verify tables
    const [tables] = await connection.query('SHOW TABLES');
    console.log('📋 Created tables:');
    tables.forEach(row => {
      const tableName = Object.values(row)[0];
      console.log(`  - ${tableName}`);
    });

    // Check test data
    console.log('\n📊 Test data counts:');
    const [customers] = await connection.query('SELECT COUNT(*) as count FROM customers');
    const [restaurants] = await connection.query('SELECT COUNT(*) as count FROM restaurants');
    const [drivers] = await connection.query('SELECT COUNT(*) as count FROM drivers');

    console.log(`  Customers: ${customers[0].count}`);
    console.log(`  Restaurants: ${restaurants[0].count}`);
    console.log(`  Drivers: ${drivers[0].count}`);

    console.log('\n🎉 Database recreation complete!');
    console.log('\n📝 Test accounts:');
    console.log('  Customer: customer@test.com / password123');
    console.log('  Restaurant: restaurant@test.com / password123');
    console.log('  Driver: driver@test.com / password123\n');

    await connection.end();

  } catch (error) {
    console.error('❌ Error recreating database:', error);
    process.exit(1);
  }
}

recreateDatabase();
