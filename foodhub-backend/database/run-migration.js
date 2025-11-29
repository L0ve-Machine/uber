require('dotenv').config({ path: '../.env' });
const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    // Create connection
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'foodhub_user',
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || 'foodhub',
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL');

    // Read migration file
    const migrationFile = path.join(__dirname, 'migrations', '001_add_delivery_sequence.sql');
    const sql = fs.readFileSync(migrationFile, 'utf8');

    console.log('📝 Running migration: 001_add_delivery_sequence.sql');

    // Execute migration
    await connection.query(sql);

    console.log('✅ Migration completed successfully');

    await connection.end();
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();
