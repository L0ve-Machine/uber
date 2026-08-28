require('dotenv').config();
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const sequelize = require('./src/config/database');
const { Customer, Restaurant, Driver, MenuItem, MenuItemOption, CustomerAddress, Coupon } = require('./src/models');

/**
 * 本番環境でのシード実行を拒否する (ASVS V2.5)
 *
 * このスクリプトはテスト用アカウントを作成する。本番 DB に対して
 * 誤って実行すると、既知のテストアカウントが本番に生えてしまう。
 * どうしても本番系ホストで実行が必要な場合は、実行者が意図を明示するため
 * ALLOW_SEED_IN_PRODUCTION=yes を付けて起動すること。
 */
function assertNotProduction() {
  if (
    process.env.NODE_ENV === 'production' &&
    process.env.ALLOW_SEED_IN_PRODUCTION !== 'yes'
  ) {
    console.error('❌ NODE_ENV=production ではシードを実行できません。');
    console.error(
      '   テスト用アカウントを本番 DB に作らないための安全装置です。'
    );
    console.error(
      '   意図的に実行する場合のみ ALLOW_SEED_IN_PRODUCTION=yes を指定してください。'
    );
    process.exit(1);
  }
}

/**
 * 実行ごとに使い捨てのランダムパスワードを生成する (ASVS V2.5)
 * 固定の password123 をやめることで、シードの痕跡が既知の認証情報として
 * 残り続けることを防ぐ。値は実行時に 1 度だけ標準出力へ表示する。
 */
function generateSeedPassword() {
  // base64url 18 バイト = 24 文字。登録時の最低長 8 文字を十分に満たす。
  return crypto.randomBytes(18).toString('base64url');
}

async function seedDatabase() {
  try {
    assertNotProduction();

    console.log('🌱 Starting database seeding...\n');

    // Hash password for all test accounts
    // パスワードは実行ごとにランダム生成し、この実行でだけ表示する
    const seedPassword = generateSeedPassword();
    const passwordHash = await bcrypt.hash(seedPassword, 10);

    // 1. Create Customer account
    const customer = await Customer.create({
      email: 'customer@test.com',
      password_hash: passwordHash,
      full_name: 'Test Customer',
      phone: '080-1234-5678',
      is_active: true
    });
    console.log('✅ Customer created:', customer.email);

    // 2. Create Customer addresses
    const addresses = await CustomerAddress.bulkCreate([
      {
        customer_id: customer.id,
        address_line: '東京都渋谷区道玄坂1-2-3',
        city: '渋谷区',
        postal_code: '150-0043',
        latitude: 35.6580,
        longitude: 139.6994,
        is_default: true,
        label: 'Home'
      },
      {
        customer_id: customer.id,
        address_line: '東京都港区六本木4-5-6',
        city: '港区',
        postal_code: '106-0032',
        latitude: 35.6641,
        longitude: 139.7318,
        is_default: false,
        label: 'Office'
      }
    ]);
    console.log('✅ Customer addresses created:', addresses.length, '個');

    // 3. Create Restaurant accounts
    const restaurant1 = await Restaurant.create({
      email: 'restaurant@test.com',
      password_hash: passwordHash,
      name: 'イタリアンビストロ',
      description: '本格的なイタリア料理をお楽しみください',
      category: 'Italian',
      phone: '03-1234-5678',
      address: '東京都渋谷区神南1-2-3',
      latitude: 35.6620,
      longitude: 139.7005,
      is_open: true,
      is_approved: true,
      min_order_amount: 1000,
      delivery_fee: 300,
      delivery_time_minutes: 30,
      rating: 4.5,
      total_reviews: 24
    });
    console.log('✅ Restaurant 1 created:', restaurant1.name);

    const restaurant2 = await Restaurant.create({
      email: 'sushi@test.com',
      password_hash: passwordHash,
      name: '寿司処 さくら',
      description: '新鮮なネタを使った本格江戸前寿司',
      category: 'Japanese',
      phone: '03-2345-6789',
      address: '東京都港区赤坂2-3-4',
      latitude: 35.6731,
      longitude: 139.7371,
      is_open: true,
      is_approved: true,
      min_order_amount: 2000,
      delivery_fee: 400,
      delivery_time_minutes: 40,
      rating: 4.8,
      total_reviews: 56
    });
    console.log('✅ Restaurant 2 created:', restaurant2.name);

    const restaurant3 = await Restaurant.create({
      email: 'burger@test.com',
      password_hash: passwordHash,
      name: 'Burger Paradise',
      description: 'ジューシーなアメリカンバーガー',
      category: 'American',
      phone: '03-3456-7890',
      address: '東京都渋谷区宇田川町3-4-5',
      latitude: 35.6607,
      longitude: 139.6986,
      is_open: true,
      is_approved: true,
      min_order_amount: 1500,
      delivery_fee: 350,
      delivery_time_minutes: 35,
      rating: 4.3,
      total_reviews: 89
    });
    console.log('✅ Restaurant 3 created:', restaurant3.name);

    // 4. Create Menu Items for Restaurant 1 (Italian)
    const menuItems1 = await MenuItem.bulkCreate([
      {
        restaurant_id: restaurant1.id,
        name: 'マルゲリータピザ',
        description: 'トマトソース、モッツァレラ、バジル',
        price: 1200,
        category: 'Pizza',
        is_available: true
      },
      {
        restaurant_id: restaurant1.id,
        name: 'ペペロンチーノ',
        description: 'にんにくとオリーブオイルのシンプルパスタ',
        price: 980,
        category: 'Pasta',
        is_available: true
      },
      {
        restaurant_id: restaurant1.id,
        name: 'カルボナーラ',
        description: 'ベーコンと卵のクリーミーパスタ',
        price: 1280,
        category: 'Pasta',
        is_available: true
      },
      {
        restaurant_id: restaurant1.id,
        name: 'クアトロフォルマッジ',
        description: '4種類のチーズピザ',
        price: 1580,
        category: 'Pizza',
        is_available: true
      },
      {
        restaurant_id: restaurant1.id,
        name: 'シーザーサラダ',
        description: 'ロメインレタスとパルメザンチーズ',
        price: 780,
        category: 'Salad',
        is_available: true
      }
    ]);
    console.log('✅ Menu items for Restaurant 1 created:', menuItems1.length, '個');

    // Add options for Pizza
    await MenuItemOption.bulkCreate([
      {
        menu_item_id: menuItems1[0].id,
        option_group_name: 'Size',
        option_name: 'Small',
        additional_price: 0
      },
      {
        menu_item_id: menuItems1[0].id,
        option_group_name: 'Size',
        option_name: 'Large',
        additional_price: 400
      },
      {
        menu_item_id: menuItems1[3].id,
        option_group_name: 'Size',
        option_name: 'Small',
        additional_price: 0
      },
      {
        menu_item_id: menuItems1[3].id,
        option_group_name: 'Size',
        option_name: 'Large',
        additional_price: 400
      }
    ]);

    // 5. Create Menu Items for Restaurant 2 (Sushi)
    const menuItems2 = await MenuItem.bulkCreate([
      {
        restaurant_id: restaurant2.id,
        name: '特選握り寿司セット',
        description: '新鮮な10貫の握り寿司',
        price: 3200,
        category: 'Sushi',
        is_available: true
      },
      {
        restaurant_id: restaurant2.id,
        name: 'ちらし寿司',
        description: '新鮮な海鮮が載ったちらし寿司',
        price: 2400,
        category: 'Sushi',
        is_available: true
      },
      {
        restaurant_id: restaurant2.id,
        name: 'サーモン巻き',
        description: '新鮮なサーモンの巻き寿司',
        price: 1200,
        category: 'Rolls',
        is_available: true
      },
      {
        restaurant_id: restaurant2.id,
        name: '天ぷら盛り合わせ',
        description: '海老と野菜の天ぷら',
        price: 1800,
        category: 'Sides',
        is_available: true
      },
      {
        restaurant_id: restaurant2.id,
        name: '味噌汁',
        description: '豆腐とワカメの味噌汁',
        price: 380,
        category: 'Soup',
        is_available: true
      }
    ]);
    console.log('✅ Menu items for Restaurant 2 created:', menuItems2.length, '個');

    // 6. Create Menu Items for Restaurant 3 (Burger)
    const menuItems3 = await MenuItem.bulkCreate([
      {
        restaurant_id: restaurant3.id,
        name: 'クラシックバーガー',
        description: 'ビーフパティ、レタス、トマト、ピクルス',
        price: 1280,
        category: 'Burgers',
        is_available: true
      },
      {
        restaurant_id: restaurant3.id,
        name: 'チーズバーガー',
        description: 'ダブルチーズとビーフパティ',
        price: 1480,
        category: 'Burgers',
        is_available: true
      },
      {
        restaurant_id: restaurant3.id,
        name: 'ベーコンバーガー',
        description: 'クリスピーベーコン入りバーガー',
        price: 1580,
        category: 'Burgers',
        is_available: true
      },
      {
        restaurant_id: restaurant3.id,
        name: 'フライドポテト',
        description: 'カリカリのフレンチフライ',
        price: 480,
        category: 'Sides',
        is_available: true
      },
      {
        restaurant_id: restaurant3.id,
        name: 'コーラ',
        description: '冷たいコカコーラ',
        price: 380,
        category: 'Drinks',
        is_available: true
      }
    ]);
    console.log('✅ Menu items for Restaurant 3 created:', menuItems3.length, '個');

    // 7. Create Driver account
    const driver = await Driver.create({
      email: 'driver@test.com',
      password_hash: passwordHash,
      full_name: 'Test Driver',
      phone: '090-1234-5678',
      vehicle_type: 'Bicycle',
      license_number: 'DRV-12345',
      is_online: false,
      is_active: true,
      is_approved: true,
      rating: 4.5,
      total_deliveries: 0
    });
    console.log('✅ Driver created:', driver.email);

    // 8. Create Coupons
    const coupons = await Coupon.bulkCreate([
      {
        code: 'WELCOME10',
        discount_type: 'percent',
        discount_value: 10,
        min_order_amount: 1000,
        max_discount: 500,
        is_active: true,
        per_user_limit: 1
      },
      {
        code: 'SAVE500',
        discount_type: 'fixed',
        discount_value: 500,
        min_order_amount: 2000,
        is_active: true,
        per_user_limit: 2
      },
      {
        code: 'FREESHIP',
        discount_type: 'fixed',
        discount_value: 300,
        min_order_amount: 1500,
        is_active: true,
        per_user_limit: 3
      }
    ]);
    console.log('✅ Coupons created:', coupons.length, '個');

    console.log('\n========================================');
    console.log('🎉 データベース初期化完了！');
    console.log('========================================\n');
    console.log('📧 ログインアカウント情報:');
    console.log('----------------------------------------');
    console.log('Customer:   customer@test.com');
    console.log('Restaurant: restaurant@test.com');
    console.log('Driver:     driver@test.com');
    console.log(`Password (この実行限り): ${seedPassword}`);
    console.log('----------------------------------------');
    console.log('⚠️  このパスワードは今この場でしか表示されません。');
    console.log('    必要なら控えたうえで、テスト完了後はアカウントごと削除してください。');
    console.log('\n📍 サーバーIP: 133.117.77.23');
    console.log('🌐 API URL: http://133.117.77.23:3000/api');
    console.log('\n利用可能なクーポンコード:');
    console.log('- WELCOME10: 10%割引（最大500円、最低注文1000円）');
    console.log('- SAVE500: 500円割引（最低注文2000円）');
    console.log('- FREESHIP: 配送料300円割引（最低注文1500円）');

    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding error:', error);
    process.exit(1);
  }
}

seedDatabase();