const sequelize = require('./src/config/database');
require('./src/models'); // Load all models

async function initDatabase() {
  try {
    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection successful!');

    // Create tables (force: false preserves existing data)
    await sequelize.sync({ force: true }); // Using force:true for initial setup
    console.log('✅ All database tables created successfully!');

    // List created tables
    const [results] = await sequelize.query("SHOW TABLES");
    console.log('\n📋 Created tables:');
    results.forEach(table => {
      console.log(`  - ${Object.values(table)[0]}`);
    });

    process.exit(0);
  } catch (error) {
    console.error('❌ Database initialization error:', error.message);
    console.error('Details:', error);
    process.exit(1);
  }
}

initDatabase();