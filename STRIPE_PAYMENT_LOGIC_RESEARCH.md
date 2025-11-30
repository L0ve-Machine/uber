# Stripe決済ロジック 完全調査レポート

調査日: 2025-11-30

---

## 業界の実際の手数料率（調査結果）

### Uber Eats（日本）

**レストランから徴収**:
- 手数料率: **35%**（配達代行利用時）
- 実質: **38%**（キャッシュレス決済手数料3%含む）
- プラン別:
  - Lite: 15%（デリバリー）+ 6%（ピックアップ）
  - Plus: 25%（デリバリー）+ 6%（ピックアップ）
  - Premium: 30%（デリバリー）+ 6%（ピックアップ）

**顧客から徴収**:
- サービス料: **約10%**（注文金額による）
- 配送料: **変動**（距離・時間・需要で変化）
- 少額注文手数料: **¥150**（780円未満の注文）

**配達員報酬**:
- 情報非公開
- 推定: 配送料の一部 + プラットフォーム補助

---

### 出前館（日本）

**レストランから徴収**:
- 配達代行利用: **35%**
  - サービス手数料: 10%
  - 配達代行手数料: 25%
- 自社配達: **7-10%**
- キャッシュレス決済手数料: **最大3%**
- 実質合計: **38%**

**配達員報酬**:
- 基本報酬: **¥400/件**（全国一律）
- ブースト: **1.1〜3倍**
- 平均: **¥650-750/件**

---

### DoorDash（米国）

**レストランから徴収**:
- 標準: **15-30%**
- オンライン注文のみ: **0%**（決済手数料2.9% + $0.30のみ）

**顧客から徴収**:
- 配送料: **$2-5**
- サービス料: **最大15%**

---

## 正しい金額の流れ（調査結果を基に）

### 例: ¥3,000の注文

```
【顧客が支払う内訳】
商品代: ¥2,000
配送料: ¥400
サービス料: ¥300（15%）
少額注文手数料: ¥0
消費税: ¥270（10%）
合計: ¥2,970

【プラットフォームが受け取る】
Stripe決済: ¥2,970
Stripe手数料: -¥107（3.6%）
実際の受取: ¥2,863

【プラットフォームから支払い】
1. レストランへ:
   商品代 ¥2,000 × (1 - 0.35) = ¥1,300
   （35%マージン = ¥700）

2. 配達員へ:
   基本報酬 ¥400
   （配送料¥400から全額）

3. プラットフォームに残る:
   レストランマージン: ¥700
   配送料マージン: ¥0（全額配達員へ）
   サービス料: ¥300
   消費税: ¥270
   小計: ¥1,270
   Stripe手数料: -¥107
   純利益: ¥1,163
```

---

## マージンが発生する箇所（正確な調査結果）

### 1. Stripe手数料（必須コスト）

**日本のStripe手数料**:
- カード決済: **3.6%**
- 国内転送: **無料**
- Instant Payout: **1.0%追加**

```
¥2,970 × 3.6% = ¥107
```

---

### 2. レストランマージン（プラットフォームの主要収益）

**業界標準**: 15-35%

```
商品代: ¥2,000
レストラン手数料率: 35%
レストランが受け取る: ¥2,000 × 0.65 = ¥1,300
プラットフォームのマージン: ¥700
```

**重要**: この¥700がプラットフォームの最大の収益源

---

### 3. 配送料の配分

**パターンA**: 配達員に全額渡す（Uber Eatsモデル）
```
顧客が払う配送料: ¥400
配達員が受け取る: ¥400
プラットフォームマージン: ¥0
```

**パターンB**: 配送料からもマージンを取る
```
顧客が払う配送料: ¥400
配達員が受け取る: ¥300（75%）
プラットフォームマージン: ¥100（25%）
```

**業界の実態**:
- Uber Eats: 配達員報酬は非公開だが、配送料全額ではない
- 出前館: 配達員に¥400-750固定、配送料は変動（差額はプラットフォーム）

---

### 4. サービス料（100%プラットフォーム収益）

**顧客から直接徴収**:
```
注文額の10-15%
¥2,000 × 15% = ¥300
```

この¥300は100%プラットフォームの収益

---

## プラットフォームの収益構造（完全版）

### 収益源（3つ）

```
1. レストランマージン: ¥700（商品代の35%）
2. 配送料マージン: ¥0-100（配送料の0-25%）
3. サービス料: ¥300（注文額の15%）
4. 消費税: ¥270（全額保持）

合計収益: ¥1,270-1,370
```

### コスト

```
1. Stripe手数料: ¥107
2. 配達員報酬: ¥400
3. 運営コスト: 変動

純利益: ¥763-863
```

---

## Stripe Connect実装コード（正確版）

### 注文作成時

```javascript
// orderController.js - createOrder関数

const itemSubtotal = 2000;              // 商品代
const deliveryFee = 400;                // 配送料
const serviceFee = 300;                 // サービス料（15%）
const tax = 270;                        // 消費税（10%）
const total = 2970;                     // 合計

// Stripe Payment Intent作成
const paymentIntent = await stripe.paymentIntents.create({
  amount: total * 100,  // ¥2,970 → 297000銭
  currency: 'jpy',
  payment_method_types: ['card'],
  transfer_group: orderNumber,
  metadata: {
    order_id: order.id,
    customer_id: customerId,
    restaurant_id: restaurantId,
    item_subtotal: itemSubtotal,
    delivery_fee: deliveryFee,
    service_fee: serviceFee,
  },
});

// DBに保存
await order.update({
  stripe_payment_id: paymentIntent.id,
  subtotal: itemSubtotal,
  delivery_fee: deliveryFee,
  service_fee: serviceFee,        // ← 新規カラム必要
  tax: tax,
  total: total,
});

// クライアントに返す
return {
  clientSecret: paymentIntent.client_secret,
  order: order,
};
```

---

### 配達完了時（レストランへ転送）

```javascript
// orderController.js - 配達完了時

// レストランマージン率を取得（設定可能にする）
const restaurantCommissionRate = 0.35;  // 35%

// レストランが受け取る金額を計算
const restaurantPayout = order.subtotal * (1 - restaurantCommissionRate);
// ¥2,000 × 0.65 = ¥1,300

// レストランに転送
const restaurantTransfer = await stripe.transfers.create({
  amount: Math.round(restaurantPayout * 100),  // ¥1,300 → 130000銭
  currency: 'jpy',
  destination: restaurant.stripe_account_id,
  transfer_group: order.order_number,
  metadata: {
    order_id: order.id,
    type: 'restaurant_payout',
    original_amount: order.subtotal,
    commission_rate: restaurantCommissionRate,
    commission_amount: order.subtotal * restaurantCommissionRate,
  },
  description: `注文 ${order.order_number} - レストラン支払い`,
});

// DBに記録
await order.update({
  restaurant_payout: restaurantPayout,
  restaurant_commission: order.subtotal * restaurantCommissionRate,
  stripe_restaurant_transfer_id: restaurantTransfer.id,
});
```

---

### 配達完了時（配達員へ転送）

```javascript
// 配達員報酬を計算（配送料全額 or 固定額）
const driverPayout = order.delivery_fee;  // ¥400（全額）
// または
// const driverPayout = 400;  // 固定報酬

// 配達員に転送
const driverTransfer = await stripe.transfers.create({
  amount: Math.round(driverPayout * 100),  // ¥400 → 40000銭
  currency: 'jpy',
  destination: driver.stripe_account_id,
  transfer_group: order.order_number,
  metadata: {
    order_id: order.id,
    type: 'driver_payout',
    delivery_fee: order.delivery_fee,
  },
  description: `注文 ${order.order_number} - 配達員報酬`,
});

// DBに記録
await order.update({
  driver_payout: driverPayout,
  stripe_driver_transfer_id: driverTransfer.id,
});
```

---

### プラットフォーム収益の計算

```javascript
// 収益計算（DBに保存）
const platformRevenue =
  (order.subtotal * restaurantCommissionRate) +  // ¥700（レストランマージン）
  (order.delivery_fee - driverPayout) +          // ¥0（配送料マージン）
  order.service_fee +                            // ¥300（サービス料）
  order.tax;                                     // ¥270（消費税）
// 合計: ¥1,270

const stripeFee = order.total * 0.036;  // ¥107
const platformProfit = platformRevenue - stripeFee;  // ¥1,163

await order.update({
  platform_revenue: platformRevenue,
  platform_profit: platformProfit,
  stripe_processing_fee: stripeFee,
});
```

---

## 必要なDB変更

### ordersテーブルに追加すべきカラム

```sql
ALTER TABLE orders
ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0.00 AFTER delivery_fee,
ADD COLUMN restaurant_commission_rate DECIMAL(5,4) DEFAULT 0.35 AFTER service_fee,
ADD COLUMN restaurant_payout DECIMAL(10,2) AFTER restaurant_commission_rate,
ADD COLUMN driver_payout DECIMAL(10,2) AFTER restaurant_payout,
ADD COLUMN platform_revenue DECIMAL(10,2) AFTER driver_payout,
ADD COLUMN platform_profit DECIMAL(10,2) AFTER platform_revenue,
ADD COLUMN stripe_processing_fee DECIMAL(10,2) AFTER platform_profit,
ADD COLUMN stripe_restaurant_transfer_id VARCHAR(255) AFTER stripe_payment_id,
ADD COLUMN stripe_driver_transfer_id VARCHAR(255) AFTER stripe_restaurant_transfer_id;
```

---

### restaurantsテーブルに追加すべきカラム

```sql
ALTER TABLE restaurants
ADD COLUMN stripe_account_id VARCHAR(255) NULL,
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN stripe_charges_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN commission_rate DECIMAL(5,4) DEFAULT 0.35 COMMENT 'プラットフォーム手数料率（デフォルト35%）';
```

---

### driversテーブルに追加すべきカラム

```sql
ALTER TABLE drivers
ADD COLUMN stripe_account_id VARCHAR(255) NULL,
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN stripe_charges_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN base_payout_per_delivery DECIMAL(10,2) DEFAULT 400.00 COMMENT '配達1件あたりの基本報酬';
```

---

## 現在のDB構造での実装可能性

### 既存カラム（使用可能）

| カラム | 用途 | 状態 |
|--------|------|------|
| `subtotal` | 商品代 | ✅ 存在 |
| `delivery_fee` | 配送料 | ✅ 存在 |
| `tax` | 消費税 | ✅ 存在 |
| `total` | 合計 | ✅ 存在 |
| `stripe_payment_id` | PaymentIntent ID | ✅ 存在 |
| `payment_method` | 支払い方法 | ✅ 存在 |

### 不足しているカラム（追加必要）

| カラム | 用途 | 必須度 |
|--------|------|--------|
| `service_fee` | サービス料 | ⚠️ 必須 |
| `restaurant_commission_rate` | レストラン手数料率 | ⚠️ 必須 |
| `restaurant_payout` | レストラン支払額 | ⚠️ 必須 |
| `driver_payout` | 配達員報酬 | ⚠️ 必須 |
| `platform_revenue` | プラットフォーム収益 | 推奨 |
| `stripe_restaurant_transfer_id` | Transfer ID（レストラン） | 推奨 |
| `stripe_driver_transfer_id` | Transfer ID（配達員） | 推奨 |

### Stripe Connect用カラム

| テーブル | カラム | 必須度 |
|---------|--------|--------|
| `restaurants` | `stripe_account_id` | 🔴 必須 |
| `restaurants` | `commission_rate` | ⚠️ 推奨 |
| `drivers` | `stripe_account_id` | 🔴 必須 |
| `drivers` | `base_payout_per_delivery` | 推奨 |

---

## 実装可能性の判定

### 結論: **実装可能だが、DB変更が必要**

**必須の変更**:
1. `orders` テーブルに `service_fee`, `restaurant_payout`, `driver_payout` 追加
2. `restaurants` テーブルに `stripe_account_id` 追加
3. `drivers` テーブルに `stripe_account_id` 追加

**最小限で動作させる場合**:
- `stripe_account_id` のみ追加
- 手数料率はコードにハードコード（35%固定）
- 支払額はその場で計算（DBに保存しない）

**推奨実装**:
- 全カラム追加
- レストランごとに手数料率を設定可能に
- 収益を正確にトラッキング

---

## 完全な実装フロー

### Phase 1: Stripe Connectアカウント作成

**レストラン登録時**:
```javascript
// restaurantController.js

// Stripe Connected Accountを作成
const account = await stripe.accounts.create({
  type: 'express',
  country: 'JP',
  email: restaurant.email,
  capabilities: {
    card_payments: { requested: true },
    transfers: { requested: true },
  },
  business_type: 'company',
  business_profile: {
    name: restaurant.name,
    product_description: 'Restaurant food service',
  },
});

// DBに保存
await restaurant.update({
  stripe_account_id: account.id,
});

// オンボーディングリンク作成
const accountLink = await stripe.accountLinks.create({
  account: account.id,
  refresh_url: 'https://yourapp.com/restaurant/stripe/refresh',
  return_url: 'https://yourapp.com/restaurant/stripe/return',
  type: 'account_onboarding',
});

// レストランにリンクを送る
return { onboarding_url: accountLink.url };
```

**配達員登録時**:
```javascript
// driverController.js

const account = await stripe.accounts.create({
  type: 'express',
  country: 'JP',
  email: driver.email,
  capabilities: {
    transfers: { requested: true },
  },
  business_type: 'individual',
  individual: {
    first_name: driver.first_name,
    last_name: driver.last_name,
    email: driver.email,
  },
});

await driver.update({
  stripe_account_id: account.id,
});
```

---

### Phase 2: 注文時の決済

**チェックアウト画面**:
```javascript
// Flutter側
final response = await checkoutApiService.createPaymentIntent(
  orderId: order.id,
);

// Stripe Elementで決済
final paymentIntent = await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: response.clientSecret,
);
```

**バックエンド**:
```javascript
// orderController.js - createPaymentIntent

// 金額計算
const itemSubtotal = calculateItemTotal(items);
const deliveryFee = restaurant.delivery_fee;
const serviceFeeRate = 0.15;  // 15%
const serviceFee = Math.round(itemSubtotal * serviceFeeRate);
const subtotalBeforeTax = itemSubtotal + deliveryFee + serviceFee;
const tax = Math.round(subtotalBeforeTax * 0.10);  // 10%
const total = subtotalBeforeTax + tax;

// Payment Intent作成
const paymentIntent = await stripe.paymentIntents.create({
  amount: total * 100,
  currency: 'jpy',
  payment_method_types: ['card'],
  transfer_group: orderNumber,
  metadata: {
    order_id: orderId,
    customer_id: customerId,
  },
});

return {
  clientSecret: paymentIntent.client_secret,
  amount: total,
};
```

---

### Phase 3: 配達完了時の転送

**Webhook処理**:
```javascript
// webhookController.js

app.post('/webhook/stripe', async (req, res) => {
  const event = stripe.webhooks.constructEvent(
    req.body,
    req.headers['stripe-signature'],
    process.env.STRIPE_WEBHOOK_SECRET
  );

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object;
    const orderId = paymentIntent.metadata.order_id;

    // 注文を取得
    const order = await Order.findByPk(orderId, {
      include: ['restaurant', 'driver']
    });

    // 配達完了している場合のみ転送
    if (order.status === 'delivered') {
      await processPayouts(order);
    }
  }

  res.json({ received: true });
});

async function processPayouts(order) {
  // 1. レストランへ転送
  const restaurantCommissionRate = order.restaurant.commission_rate || 0.35;
  const restaurantPayout = order.subtotal * (1 - restaurantCommissionRate);

  await stripe.transfers.create({
    amount: Math.round(restaurantPayout * 100),
    currency: 'jpy',
    destination: order.restaurant.stripe_account_id,
    transfer_group: order.order_number,
    source_transaction: order.stripe_payment_id,
  });

  // 2. 配達員へ転送
  const driverPayout = order.driver.base_payout_per_delivery || order.delivery_fee;

  await stripe.transfers.create({
    amount: Math.round(driverPayout * 100),
    currency: 'jpy',
    destination: order.driver.stripe_account_id,
    transfer_group: order.order_number,
    source_transaction: order.stripe_payment_id,
  });

  // 3. 収益計算
  const platformRevenue =
    (order.subtotal * restaurantCommissionRate) +
    (order.delivery_fee - driverPayout) +
    order.service_fee +
    order.tax;

  await order.update({
    restaurant_payout: restaurantPayout,
    driver_payout: driverPayout,
    platform_revenue: platformRevenue,
    payout_completed: true,
  });
}
```

---

## 実装の可否判定

### ✅ 実装可能

**理由**:
1. Stripe SDKは既にインストール済み（package.json）
2. 基本的なテーブル構造は存在
3. Payment Intent用のカラムあり（stripe_payment_id）

### ⚠️ 必要な作業

**必須**:
1. DB変更（9カラム追加）
2. Stripe Connect設定（管理画面）
3. レストラン・配達員のオンボーディングフロー
4. Webhook実装

**推定工数**:
- DB変更: 10分
- バックエンド実装: 3-4時間
- Flutter実装: 2-3時間
- テスト: 1-2時間
- 合計: **6-9時間**

---

## 正しい理解（最終版）

### あなたの理解は完全に正しい

**支払い内訳**:
```
顧客が支払う: 商品代 + 配送料 + サービス料 + 税
```

**レストランが受け取る**:
```
商品代 × 0.65（35%マージン）
```

**配達員が受け取る**:
```
配送料（全額または固定額）
```

**プラットフォームが受け取る**:
```
1. レストランマージン（35%）
2. サービス料（100%）
3. 配送料の一部（オプション）
4. 消費税（100%）
```

---

Sources:
- [Uber Eats レストラン手数料 2025年最新](https://aumo.jp/articles/646619)
- [Uber Eats 店舗側手数料のリアル](https://012cloud.jp/article/uber-eats-comission)
- [出前館 加盟店手数料35%](https://www.delinavi.net/entry/出前館_加盟店)
- [Uber Eats Commission Fee Breakdown](https://www.restolabs.com/blog/uber-eats-commission-fee)
- [Stripe Connect Implementation Tutorial](https://www.cjav.dev/articles/taking-a-cut-with-stripe-connect)
- [Food Delivery Platform Revenue Models](https://pubsonline.informs.org/doi/10.1287/mnsc.2023.00435)
