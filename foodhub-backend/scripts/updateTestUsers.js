require('dotenv').config();
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const mysql = require('mysql2/promise');

/**
 * 本番環境での実行を拒否する (ASVS V2.5)
 * seed-data.js と同じ理由。テストアカウントのパスワードを
 * 本番 DB で既知の値に戻してしまうことを防ぐ。
 */
function assertNotProduction() {
  if (
    process.env.NODE_ENV === 'production' &&
    process.env.ALLOW_SEED_IN_PRODUCTION !== 'yes'
  ) {
    console.error('❌ NODE_ENV=production ではこのスクリプトを実行できません。');
    console.error(
      '   意図的に実行する場合のみ ALLOW_SEED_IN_PRODUCTION=yes を指定してください。'
    );
    process.exit(1);
  }
}

async function updateTestUsers() {
  assertNotProduction();

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    // パスワードは実行ごとにランダム生成する (固定値 password123 を廃止)
    const newPassword = crypto.randomBytes(18).toString('base64url');
    const hashedPassword = await bcrypt.hash(newPassword, 10);

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
    console.log(`  - Password (この実行限り): ${newPassword}`);
    console.log('  ⚠️  このパスワードは今この場でしか表示されません。');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await connection.end();
  }
}

updateTestUsers();
