require('dotenv').config();
const mysql = require('mysql2/promise');

async function setupDatabase() {
  console.log('🔧 Food Hub Database Auto-Setup\n');

  try {
    // Try to connect as root with no password
    console.log('🔌 Attempting to connect to MySQL as root...');
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      multipleStatements: true,
    });

    console.log('✅ Connected to MySQL as root\n');

    // Drop existing user if exists
    console.log('🗑️  Dropping existing foodhub_user if exists...');
    await connection.query(`DROP USER IF EXISTS 'foodhub_user'@'localhost'`);

    // Create the foodhub user
    console.log('📝 Creating foodhub_user...');
    await connection.query(`
      CREATE USER 'foodhub_user'@'localhost'
      IDENTIFIED BY '${process.env.DB_PASSWORD}'
    `);
    console.log('✅ User created\n');

    // Drop and create database
    console.log('📦 Recreating foodhub database...');
    await connection.query('DROP DATABASE IF EXISTS foodhub');
    await connection.query('CREATE DATABASE foodhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
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
    console.log('✅ Ready to initialize tables!');
    console.log('   Run: node init-database.js\n');

    process.exit(0);

  } catch (error) {
    console.error('❌ Setup error:', error.message);

    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.log('\n⚠️  Cannot connect to MySQL as root with empty password.');
      console.log('\n📋 Manual setup required. Run these MySQL commands:');
      console.log('----------------------------------------');
      console.log('mysql -u root -p');
      console.log('');
      console.log(`DROP USER IF EXISTS 'foodhub_user'@'localhost';`);
      console.log(`CREATE USER 'foodhub_user'@'localhost' IDENTIFIED BY '${process.env.DB_PASSWORD}';`);
      console.log(`DROP DATABASE IF EXISTS foodhub;`);
      console.log(`CREATE DATABASE foodhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`);
      console.log(`GRANT ALL PRIVILEGES ON foodhub.* TO 'foodhub_user'@'localhost';`);
      console.log(`FLUSH PRIVILEGES;`);
      console.log(`EXIT;`);
      console.log('----------------------------------------');
      console.log('\nThen run: node init-database.js\n');
    }

    process.exit(1);
  }
}

setupDatabase();
