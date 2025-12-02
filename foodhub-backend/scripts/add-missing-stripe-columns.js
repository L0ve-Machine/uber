require('dotenv').config();
const sequelize = require('../src/config/database');

async function addColumnIfNotExists(tableName, columnName, columnDefinition) {
  try {
    // Check if column exists
    const [results] = await sequelize.query(`
      SELECT COLUMN_NAME
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = '${tableName}'
        AND COLUMN_NAME = '${columnName}'
    `);

    if (results.length === 0) {
      // Column doesn't exist, add it
      await sequelize.query(`
        ALTER TABLE ${tableName}
        ADD COLUMN ${columnName} ${columnDefinition}
      `);
      console.log(`✅ Added ${columnName} column`);
    } else {
      console.log(`⏭️  ${columnName} column already exists, skipping`);
    }
  } catch (error) {
    console.error(`❌ Error adding ${columnName}:`, error.message);
    throw error;
  }
}

async function addMissingStripeColumns() {
  try {
    console.log('🔧 Adding missing Stripe columns to restaurants table...');

    await addColumnIfNotExists('restaurants', 'stripe_account_id', 'VARCHAR(255) NULL');
    await addColumnIfNotExists('restaurants', 'stripe_onboarding_completed', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfNotExists('restaurants', 'stripe_charges_enabled', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfNotExists('restaurants', 'stripe_payouts_enabled', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfNotExists('restaurants', 'commission_rate', 'DECIMAL(5, 4) DEFAULT 0.35');

    console.log('🔧 Adding missing Stripe columns to drivers table...');

    await addColumnIfNotExists('drivers', 'stripe_account_id', 'VARCHAR(255) NULL');
    await addColumnIfNotExists('drivers', 'stripe_onboarding_completed', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfNotExists('drivers', 'stripe_payouts_enabled', 'BOOLEAN DEFAULT FALSE');
    await addColumnIfNotExists('drivers', 'base_payout_per_delivery', 'DECIMAL(10, 2) DEFAULT 400.00');

    console.log('🎉 All missing Stripe columns processed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addMissingStripeColumns();
