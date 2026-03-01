/**
 * ヒートマップ・クラスタリングテスト用データ作成スクリプト
 *
 * 目的: 配達員ダッシュボードの地図機能をテストするため、
 *       首都圏に分散したレストランと配達リクエストを大量作成
 */

require('dotenv').config();
const { sequelize, Restaurant, Order, CustomerAddress, Customer } = require('../src/models');

const AREAS = [
  {
    name: '新宿エリア',
    center: { lat: 35.6938, lng: 139.7036 },
    restaurants: 3,
    ordersPerRestaurant: 8,  // 合計24件 → オレンジクラスタ
  },
  {
    name: '池袋エリア',
    center: { lat: 35.7295, lng: 139.7109 },
    restaurants: 3,
    ordersPerRestaurant: 15, // 合計45件 → 赤クラスタ
  },
  {
    name: '品川エリア',
    center: { lat: 35.6284, lng: 139.7387 },
    restaurants: 2,
    ordersPerRestaurant: 4,  // 合計8件 → 緑クラスタ
  },
  {
    name: '六本木エリア',
    center: { lat: 35.6627, lng: 139.7298 },
    restaurants: 2,
    ordersPerRestaurant: 6,  // 合計12件 → 黄色クラスタ
  },
];

const RESTAURANT_CATEGORIES = ['和食', '中華', 'イタリアン', '韓国料理', 'アメリカン', 'タイ料理'];
const RESTAURANT_NAMES = [
  'らーめん亭', '焼肉王', 'ピザハウス', 'カフェ', '寿司バー',
  '中華飯店', 'タコス屋', '串焼き処', 'パスタ専門店', 'カレーハウス',
  'ハンバーガーショップ', '天ぷら屋', 'ステーキハウス', 'うどん処', 'そば処',
];

// エリア中心から半径内のランダムな座標を生成（約1km範囲）
function getRandomLocation(center, radiusKm = 1.0) {
  const earthRadius = 6371; // km
  const radiusInDegrees = radiusKm / earthRadius * (180 / Math.PI);

  const u = Math.random();
  const v = Math.random();
  const w = radiusInDegrees * Math.sqrt(u);
  const t = 2 * Math.PI * v;
  const x = w * Math.cos(t);
  const y = w * Math.sin(t);

  const newLat = center.lat + y;
  const newLng = center.lng + x / Math.cos(center.lat * Math.PI / 180);

  return {
    latitude: parseFloat(newLat.toFixed(8)),
    longitude: parseFloat(newLng.toFixed(8)),
  };
}

async function createTestData() {
  try {
    console.log('🚀 ヒートマップテストデータ作成開始...\n');

    // 顧客の住所を取得（配達先として使用）
    const addresses = await CustomerAddress.findAll({
      where: { customer_id: 1 },
      limit: 10,
    });

    if (addresses.length === 0) {
      console.error('❌ 顧客の住所が見つかりません。先に住所を登録してください。');
      return;
    }

    let totalRestaurants = 0;
    let totalOrders = 0;

    // エリアごとにレストランと注文を作成
    for (const area of AREAS) {
      console.log(`\n📍 ${area.name} にデータ作成中...`);
      console.log(`   中心座標: ${area.center.lat}, ${area.center.lng}`);

      // レストランを作成
      for (let i = 0; i < area.restaurants; i++) {
        const location = getRandomLocation(area.center);
        const nameIndex = totalRestaurants % RESTAURANT_NAMES.length;
        const categoryIndex = totalRestaurants % RESTAURANT_CATEGORIES.length;

        const restaurant = await Restaurant.create({
          name: `${RESTAURANT_NAMES[nameIndex]}（${area.name}）`,
          email: `test-restaurant-${totalRestaurants}@foodhub.test`,
          password_hash: '$2b$10$dummy.hash.for.test.restaurants.only',
          category: RESTAURANT_CATEGORIES[categoryIndex],
          address: `東京都 ${area.name} サンプル住所`,
          phone: `03-${String(1000 + totalRestaurants).padStart(4, '0')}-${String(Math.floor(Math.random() * 10000)).padStart(4, '0')}`,
          latitude: location.latitude,
          longitude: location.longitude,
          rating: (Math.random() * 2 + 3).toFixed(1), // 3.0-5.0
          delivery_fee: Math.floor(Math.random() * 300) + 200, // 200-500円
          delivery_time_minutes: Math.floor(Math.random() * 20) + 20, // 20-40分
          is_open: true,
        });

        console.log(`   ✅ レストラン作成: ${restaurant.name} (ID: ${restaurant.id})`);
        totalRestaurants++;

        // 各レストランに複数の注文を作成
        for (let j = 0; j < area.ordersPerRestaurant; j++) {
          const addressIndex = Math.floor(Math.random() * addresses.length);
          const address = addresses[addressIndex];

          const subtotal = Math.floor(Math.random() * 3000) + 1000; // 1000-4000円
          const deliveryFee = restaurant.delivery_fee;
          const tax = Math.floor(subtotal * 0.1);
          const total = subtotal + deliveryFee + tax;

          const order = await Order.create({
            order_number: `TEST${Date.now()}${totalOrders}`,
            customer_id: 1,
            restaurant_id: restaurant.id,
            delivery_address_id: address.id,
            status: 'ready',  // 配達員が受諾可能な状態
            driver_id: null,
            subtotal: subtotal,
            delivery_fee: deliveryFee,
            tax: tax,
            discount: 0,
            total: total,
            payment_method: 'cash',
            pickup_pin: String(Math.floor(Math.random() * 9000) + 1000), // 4桁PIN
          });

          totalOrders++;
        }

        console.log(`      → 配達リクエスト ${area.ordersPerRestaurant}件 作成`);
      }

      console.log(`   📦 ${area.name} 完了: ${area.restaurants}店舗、${area.restaurants * area.ordersPerRestaurant}件の配達`);
    }

    console.log('\n' + '='.repeat(50));
    console.log('✅ テストデータ作成完了！');
    console.log('='.repeat(50));
    console.log(`📊 統計:`);
    console.log(`   - 新規レストラン: ${totalRestaurants}店舗`);
    console.log(`   - 配達リクエスト: ${totalOrders}件`);
    console.log(`\n🎯 期待されるクラスタ:`);
    console.log(`   🟢 緑（品川）: 8件`);
    console.log(`   🟡 黄色（六本木）: 12件`);
    console.log(`   🟡 黄色（渋谷）: 既存店の配達次第`);
    console.log(`   🟠 オレンジ（新宿）: 24件`);
    console.log(`   🔴 赤（池袋）: 45件`);
    console.log(`\n📱 配達員アプリで確認してください！`);

  } catch (error) {
    console.error('❌ エラー発生:', error);
  } finally {
    await sequelize.close();
  }
}

createTestData();
