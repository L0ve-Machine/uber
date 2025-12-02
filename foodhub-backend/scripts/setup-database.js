require('dotenv').config();
const mysql = require('mysql2/promise');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function setupDatabase() {
  console.log('🔧 Food Hub Database Setup\n');
  console.log('This script will:');
  console.log('1. Create the foodhub_user MySQL user');
  console.log('2. Create the foodhub database');
  console.log('3. Grant necessary privileges\n');

  try {
    // Prompt for root password
    const rootPassword = await question('Enter MySQL root password (press Enter if no password): ');
    console.log('');

    // Connect as root
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: rootPassword,
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL as root\n');

    // Create the foodhub user
    console.log('📝 Creating foodhub_user...');
    await connection.query(`
      CREATE USER IF NOT EXISTS 'foodhub_user'@'localhost'
      IDENTIFIED BY '${process.env.DB_PASSWORD}'
    `);
    console.log('✅ User created\n');

    // Create database
    console.log('📦 Creating foodhub database...');
    await connection.query('CREATE DATABASE IF NOT EXISTS foodhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    console.log('✅ Database created\n');

    // Grant privileges
    console.log('🔐 Granting privileges...');
    await connection.query(`
      GRANT ALL PRIVILEGES ON foodhub.* TO 'foodhub_user'@'localhost';
      FLUSH PRIVILEGES;
    `);
    console.log('✅ Privileges granted\n');

    await connection.end();

    console.log('========================================');
    console.log('🎉 Database setup complete!');
    console.log('========================================\n');
    console.log('Database credentials:');
    console.log(`  User: ${process.env.DB_USER}`);
    console.log(`  Password: ${process.env.DB_PASSWORD}`);
    console.log(`  Database: ${process.env.DB_NAME}\n`);
    console.log('Next steps:');
    console.log('1. Run: node init-database.js');
    console.log('2. Run: node seed-data.js\n');

    rl.close();
    process.exit(0);

  } catch (error) {
    console.error('❌ Setup error:', error.message);
    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.log('\n⚠️  Incorrect root password. Please try again.');
    }
    rl.close();
    process.exit(1);
  }
}

setupDatabase();
