require('dotenv').config();
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');

async function updateTestUsers() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    // Hash password: "password123"
    const hashedPassword = await bcrypt.hash('password123', 10);

    // Update customer
    await connection.execute(
      'UPDATE customers SET password_hash = ? WHERE email = ?',
      [hashedPassword, 'customer@test.com']
    );
    console.log('✅ Updated customer test user');

    // Update restaurant
    await connection.execute(
      'UPDATE restaurants SET password_hash = ? WHERE email = ?',
      [hashedPassword, 'restaurant@test.com']
    );
    console.log('✅ Updated restaurant test user');

    // Update driver
    await connection.execute(
      'UPDATE drivers SET password_hash = ? WHERE email = ?',
      [hashedPassword, 'driver@test.com']
    );
    console.log('✅ Updated driver test user');

    console.log('\n✅ All test users updated!');
    console.log('Test credentials:');
    console.log('  - Email: customer@test.com / restaurant@test.com / driver@test.com');
    console.log('  - Password: password123');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await connection.end();
  }
}

updateTestUsers();
