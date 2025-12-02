const mysql = require('mysql2/promise');
require('dotenv').config();

async function migrateAddressStructure() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || 'rootpassword',
    database: process.env.DB_NAME || 'foodhub',
  });

  try {
    console.log('🔄 Starting address structure migration...');

    // Step 1: Add new columns
    console.log('📝 Adding address_line_1 and address_line_2 columns...');
    await connection.query(`
      ALTER TABLE customer_addresses
      ADD COLUMN address_line_1 VARCHAR(255) NULL AFTER customer_id,
      ADD COLUMN address_line_2 VARCHAR(255) NULL AFTER address_line_1
    `);

    // Step 2: Migrate data from address_line to address_line_1
    console.log('📦 Migrating existing data...');
    await connection.query(`
      UPDATE customer_addresses
      SET address_line_1 = address_line
      WHERE address_line_1 IS NULL
    `);

    // Step 3: Make address_line_1 NOT NULL
    console.log('🔒 Setting address_line_1 to NOT NULL...');
    await connection.query(`
      ALTER TABLE customer_addresses
      MODIFY COLUMN address_line_1 VARCHAR(255) NOT NULL
    `);

    // Step 4: Drop old columns
    console.log('🗑️  Dropping old address_line and city columns...');
    await connection.query(`
      ALTER TABLE customer_addresses
      DROP COLUMN address_line,
      DROP COLUMN city
    `);

    console.log('✅ Migration completed successfully!');

    // Show new structure
    const [rows] = await connection.query('DESCRIBE customer_addresses');
    console.log('\n📋 New table structure:');
    console.table(rows);

    // Show sample data
    const [data] = await connection.query('SELECT * FROM customer_addresses LIMIT 3');
    console.log('\n📊 Sample data:');
    console.table(data);

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  } finally {
    await connection.end();
  }
}

migrateAddressStructure()
  .then(() => {
    console.log('\n🎉 All done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Fatal error:', error);
    process.exit(1);
  });
