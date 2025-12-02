require('dotenv').config();
const sequelize = require('../src/config/database');

async function addTestCoordinates() {
  try {
    console.log('🗺️  Adding test coordinates to restaurants and addresses...');

    // Update restaurants with Tokyo coordinates
    await sequelize.query(`
      UPDATE restaurants
      SET
        latitude = 35.6762 + (RAND() * 0.02 - 0.01),
        longitude = 139.6503 + (RAND() * 0.02 - 0.01)
      WHERE latitude IS NULL OR longitude IS NULL
    `);

    // Update customer addresses with nearby Tokyo coordinates
    await sequelize.query(`
      UPDATE customer_addresses
      SET
        latitude = 35.6762 + (RAND() * 0.04 - 0.02),
        longitude = 139.6503 + (RAND() * 0.04 - 0.02)
      WHERE latitude IS NULL OR longitude IS NULL
    `);

    console.log('✅ Test coordinates added successfully!');
    console.log('📍 Restaurants: Tokyo area (35.67°N, 139.65°E)');
    console.log('📍 Addresses: Within 2km of Tokyo center');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addTestCoordinates();
