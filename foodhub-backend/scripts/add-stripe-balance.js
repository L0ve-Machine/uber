require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Stripeテストアカウントにavailable balanceを追加
 * テストカード 4000000000000077 を使用
 */
async function addBalance() {
  try {
    console.log('💳 Stripeアカウントに残高を追加します...\n');

    // 現在の残高を確認
    console.log('【現在の残高】');
    const balance = await stripe.balance.retrieve();
    const availableJPY = balance.available.find(b => b.currency === 'jpy');
    const pendingJPY = balance.pending.find(b => b.currency === 'jpy');

    console.log(`  Available: ¥${availableJPY ? availableJPY.amount : 0}`);
    console.log(`  Pending: ¥${pendingJPY ? pendingJPY.amount : 0}`);
    console.log();

    // 特別なテストカードで決済を作成（10,000円）
    console.log('【決済を作成】');
    const amount = 10000; // ¥10,000

    // 4000000000000077 カードでPayment Methodを作成
    const paymentMethod = await stripe.paymentMethods.create({
      type: 'card',
      card: {
        number: '4000000000000077',
        exp_month: 12,
        exp_year: 2026,
        cvc: '123',
      },
    });

    console.log(`  Payment Method作成: ${paymentMethod.id}`);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: 'jpy',
      payment_method: paymentMethod.id,
      confirm: true,
      automatic_payment_methods: {
        enabled: false,
      },
    });

    console.log(`  ✅ 決済成功: ¥${amount}`);
    console.log(`  Payment Intent ID: ${paymentIntent.id}`);
    console.log(`  Status: ${paymentIntent.status}`);
    console.log();

    // 更新後の残高を確認
    console.log('【更新後の残高】');
    const newBalance = await stripe.balance.retrieve();
    const newAvailableJPY = newBalance.available.find(b => b.currency === 'jpy');
    const newPendingJPY = newBalance.pending.find(b => b.currency === 'jpy');

    console.log(`  Available: ¥${newAvailableJPY ? newAvailableJPY.amount : 0}`);
    console.log(`  Pending: ¥${newPendingJPY ? newPendingJPY.amount : 0}`);
    console.log();

    console.log('✨ 残高追加完了！');
    console.log('これでTransferが実行できるようになりました。');
    console.log();
    console.log('次の配達完了時に、レストラン・配達員への送金が成功します。');

    process.exit(0);
  } catch (error) {
    console.error('❌ エラー:', error.message);
    if (error.raw) {
      console.error('詳細:', error.raw.message);
    }
    process.exit(1);
  }
}

addBalance();
