# Stripe決済統合 詳細実装計画書

作成日: 2025-11-30
対象: FoodHub アプリ

---

## 事前調査結果サマリー

### 既存の実装状況

**バックエンド**:
- Stripe SDK: インストール済み（v20.0.0）
- 環境変数: STRIPE_SECRET_KEY 設定済み（テストキー）
- 既存コード: **Stripe決済処理なし**（現金のみ）

**フロントエンド**:
- flutter_stripe: インストール済み（v10.2.0）
- 環境変数: stripePublishableKey 設定済み（プレースホルダー）
- 既存コード: **Stripe決済処理なし**

**現在の注文作成フロー**:
```javascript
// orderController.js:38-184
1. カート商品の合計計算（subtotal）
2. 配送料を追加（restaurant.delivery_fee）
3. 消費税計算（subtotal × 0.1）
4. 合計 = subtotal + delivery_fee + tax
5. DBに保存（payment_method: 'cash' or 'card'）
6. 決済処理: なし（保存のみ）
```

**問題点**:
- サービス料が計算されていない
- Stripe決済が実装されていない
- レストラン・配達員への支払いロジックなし

---

## 既存データベース構造の完全分析

### ordersテーブル（現在）

| カラム名 | 型 | 用途 | 状態 |
|---------|---|------|------|
| `id` | INT | 注文ID | ✅ 存在 |
| `order_number` | VARCHAR(20) | 注文番号 | ✅ 存在 |
| `customer_id` | INT | 顧客ID | ✅ 存在 |
| `restaurant_id` | INT | レストランID | ✅ 存在 |
| `driver_id` | INT | 配達員ID | ✅ 存在 |
| `delivery_address_id` | INT | 配達先ID | ✅ 存在 |
| `status` | ENUM | ステータス | ✅ 存在 |
| `subtotal` | DECIMAL(10,2) | 商品小計 | ✅ 存在 |
| `delivery_fee` | DECIMAL(10,2) | 配送料 | ✅ 存在 |
| `tax` | DECIMAL(10,2) | 消費税 | ✅ 存在 |
| `discount` | DECIMAL(10,2) | 割引額 | ✅ 存在 |
| `total` | DECIMAL(10,2) | 合計 | ✅ 存在 |
| `payment_method` | VARCHAR(50) | 支払い方法 | ✅ 存在 |
| `stripe_payment_id` | VARCHAR(255) | PaymentIntent ID | ✅ 存在 |
| `special_instructions` | TEXT | 特別指示 | ✅ 存在 |
| `scheduled_at` | TIMESTAMP | 予約時刻 | ✅ 存在 |
| `created_at` | TIMESTAMP | 作成日時 | ✅ 存在 |
| `accepted_at` | TIMESTAMP | 受付日時 | ✅ 存在 |
| `picked_up_at` | TIMESTAMP | ピックアップ日時 | ✅ 存在 |
| `delivered_at` | TIMESTAMP | 配達完了日時 | ✅ 存在 |
| `cancelled_at` | TIMESTAMP | キャンセル日時 | ✅ 存在 |

**不足しているカラム（追加必要）**:

| カラム名 | 型 | 用途 | 必須度 |
|---------|---|------|--------|
| `service_fee` | DECIMAL(10,2) | サービス料 | 🔴 必須 |
| `restaurant_commission_rate` | DECIMAL(5,4) | レストラン手数料率 | 🟡 推奨 |
| `restaurant_payout` | DECIMAL(10,2) | レストラン支払額 | 🔴 必須 |
| `driver_payout` | DECIMAL(10,2) | 配達員支払額 | 🔴 必須 |
| `platform_revenue` | DECIMAL(10,2) | プラットフォーム収益 | 🟢 任意 |
| `stripe_restaurant_transfer_id` | VARCHAR(255) | レストラン Transfer ID | 🟢 任意 |
| `stripe_driver_transfer_id` | VARCHAR(255) | 配達員 Transfer ID | 🟢 任意 |
| `payout_completed` | BOOLEAN | 支払い完了フラグ | 🟡 推奨 |

---

### restaurantsテーブル（現在）

| カラム名 | 型 | 用途 | 状態 |
|---------|---|------|------|
| `id` | INT | ID | ✅ 存在 |
| `email` | VARCHAR(255) | メール | ✅ 存在 |
| `name` | VARCHAR(255) | 店名 | ✅ 存在 |
| `delivery_fee` | DECIMAL(10,2) | 配送料 | ✅ 存在 |
| ... | ... | ... | ✅ 存在 |

**不足しているカラム（追加必要）**:

| カラム名 | 型 | 用途 | 必須度 |
|---------|---|------|--------|
| `stripe_account_id` | VARCHAR(255) | Stripe Connect Account ID | 🔴 必須 |
| `stripe_onboarding_completed` | BOOLEAN | オンボーディング完了 | 🔴 必須 |
| `stripe_charges_enabled` | BOOLEAN | 決済受付可能 | 🟡 推奨 |
| `stripe_payouts_enabled` | BOOLEAN | 支払い受取可能 | 🟡 推奨 |
| `commission_rate` | DECIMAL(5,4) | 手数料率 | 🟡 推奨 |

---

### driversテーブル（現在）

| カラム名 | 型 | 用途 | 状態 |
|---------|---|------|------|
| `id` | INT | ID | ✅ 存在 |
| `email` | VARCHAR(255) | メール | ✅ 存在 |
| `full_name` | VARCHAR(100) | 氏名 | ✅ 存在 |
| `bank_account_info` | JSON | 銀行口座情報 | ✅ 存在 |
| ... | ... | ... | ✅ 存在 |

**不足しているカラム（追加必要）**:

| カラム名 | 型 | 用途 | 必須度 |
|---------|---|------|--------|
| `stripe_account_id` | VARCHAR(255) | Stripe Connect Account ID | 🔴 必須 |
| `stripe_onboarding_completed` | BOOLEAN | オンボーディング完了 | 🔴 必須 |
| `stripe_payouts_enabled` | BOOLEAN | 支払い受取可能 | 🟡 推奨 |
| `base_payout_per_delivery` | DECIMAL(10,2) | 配達1件あたり報酬 | 🟡 推奨 |

---

## 不足しているカラムの最終リスト

### 🔴 最小限の実装に必要（6カラム）

**ordersテーブル**:
1. `service_fee` DECIMAL(10,2) - サービス料
2. `restaurant_payout` DECIMAL(10,2) - レストラン支払額
3. `driver_payout` DECIMAL(10,2) - 配達員支払額

**restaurantsテーブル**:
4. `stripe_account_id` VARCHAR(255) - Stripe Account ID
5. `stripe_onboarding_completed` BOOLEAN - オンボーディング完了

**driversテーブル**:
6. `stripe_account_id` VARCHAR(255) - Stripe Account ID

### 🟡 推奨追加（6カラム）

**ordersテーブル**:
1. `restaurant_commission_rate` DECIMAL(5,4) - 手数料率
2. `payout_completed` BOOLEAN - 支払い完了
3. `stripe_restaurant_transfer_id` VARCHAR(255) - Transfer ID
4. `stripe_driver_transfer_id` VARCHAR(255) - Transfer ID

**restaurantsテーブル**:
5. `commission_rate` DECIMAL(5,4) - デフォルト手数料率

**driversテーブル**:
6. `base_payout_per_delivery` DECIMAL(10,2) - 基本報酬

---

## 既存コードの問題点

### 問題1: サービス料が計算されていない

**現在のコード**（orderController.js:117-120）:
```javascript
const delivery_fee = parseFloat(restaurant.delivery_fee);
const tax = subtotal * 0.1; // 10% tax
const total = subtotal + delivery_fee + tax;
```

**問題**: サービス料が含まれていない

**修正後**:
```javascript
const delivery_fee = parseFloat(restaurant.delivery_fee);
const service_fee_rate = 0.15;  // 15%
const service_fee = subtotal * service_fee_rate;
const subtotal_before_tax = subtotal + delivery_fee + service_fee;
const tax = subtotal_before_tax * 0.1;  // 10% tax
const total = subtotal_before_tax + tax;
```

---

### 問題2: Flutter側の金額計算が不正確

**現在のコード**（cart_provider.dart:94-110）:
```dart
double get subtotal => state.fold(0.0, (sum, item) => sum + item.totalPrice);
double get tax => subtotal * 0.1;
double get deliveryFee => 300.0;  // 固定値
double get total => subtotal + tax + deliveryFee;
```

**問題**:
- サービス料がない
- 配送料が固定値（レストランごとに異なるはず）
- 税の計算が間違い（サービス料・配送料にも税がかかる）

**修正後**:
```dart
double get subtotal => state.fold(0.0, (sum, item) => sum + item.totalPrice);
double get deliveryFee => _getRestaurantDeliveryFee();  // レストランから取得
double get serviceFee => subtotal * 0.15;  // 15%
double get subtotalBeforeTax => subtotal + deliveryFee + serviceFee;
double get tax => subtotalBeforeTax * 0.1;  // 10%
double get total => subtotalBeforeTax + tax;
```

---

## 実装の詳細計画

### Phase 1: データベース変更

#### マイグレーションSQL

```sql
-- ファイル: foodhub-backend/database/migrations/002_add_stripe_payment_columns.sql

USE foodhub;

-- ========== ordersテーブル ==========

-- サービス料
ALTER TABLE orders
ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0.00
AFTER delivery_fee
COMMENT 'サービス料（プラットフォーム収益）';

-- レストラン手数料率
ALTER TABLE orders
ADD COLUMN restaurant_commission_rate DECIMAL(5,4) DEFAULT 0.35
AFTER service_fee
COMMENT 'レストラン手数料率（例: 0.35 = 35%）';

-- レストラン支払額
ALTER TABLE orders
ADD COLUMN restaurant_payout DECIMAL(10,2)
AFTER restaurant_commission_rate
COMMENT 'レストランへの実際の支払額';

-- 配達員支払額
ALTER TABLE orders
ADD COLUMN driver_payout DECIMAL(10,2)
AFTER restaurant_payout
COMMENT '配達員への実際の支払額';

-- プラットフォーム収益
ALTER TABLE orders
ADD COLUMN platform_revenue DECIMAL(10,2)
AFTER driver_payout
COMMENT 'プラットフォームの収益（手数料+サービス料+税）';

-- Stripe Transfer ID（レストラン）
ALTER TABLE orders
ADD COLUMN stripe_restaurant_transfer_id VARCHAR(255)
AFTER stripe_payment_id
COMMENT 'Stripe Transfer ID（レストランへの送金）';

-- Stripe Transfer ID（配達員）
ALTER TABLE orders
ADD COLUMN stripe_driver_transfer_id VARCHAR(255)
AFTER stripe_restaurant_transfer_id
COMMENT 'Stripe Transfer ID（配達員への送金）';

-- 支払い完了フラグ
ALTER TABLE orders
ADD COLUMN payout_completed BOOLEAN DEFAULT FALSE
AFTER driver_payout
COMMENT 'レストラン・配達員への支払いが完了したか';

-- ========== restaurantsテーブル ==========

-- Stripe Account ID
ALTER TABLE restaurants
ADD COLUMN stripe_account_id VARCHAR(255) NULL
AFTER is_approved
COMMENT 'Stripe Connect Account ID';

-- オンボーディング完了
ALTER TABLE restaurants
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE
AFTER stripe_account_id
COMMENT 'Stripeオンボーディング完了フラグ';

-- 決済受付可能
ALTER TABLE restaurants
ADD COLUMN stripe_charges_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_onboarding_completed
COMMENT 'Stripe決済を受け付けられるか';

-- 支払い受取可能
ALTER TABLE restaurants
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_charges_enabled
COMMENT 'Stripe支払いを受け取れるか';

-- 手数料率（レストランごとに設定可能）
ALTER TABLE restaurants
ADD COLUMN commission_rate DECIMAL(5,4) DEFAULT 0.35
AFTER stripe_payouts_enabled
COMMENT 'プラットフォーム手数料率（デフォルト35%）';

-- インデックス追加
CREATE INDEX idx_stripe_account ON restaurants(stripe_account_id);

-- ========== driversテーブル ==========

-- Stripe Account ID
ALTER TABLE drivers
ADD COLUMN stripe_account_id VARCHAR(255) NULL
AFTER bank_account_info
COMMENT 'Stripe Connect Account ID';

-- オンボーディング完了
ALTER TABLE drivers
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE
AFTER stripe_account_id
COMMENT 'Stripeオンボーディング完了フラグ';

-- 支払い受取可能
ALTER TABLE drivers
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_onboarding_completed
COMMENT 'Stripe支払いを受け取れるか';

-- 配達1件あたりの基本報酬
ALTER TABLE drivers
ADD COLUMN base_payout_per_delivery DECIMAL(10,2) DEFAULT 400.00
AFTER stripe_payouts_enabled
COMMENT '配達1件あたりの基本報酬（デフォルト¥400）';

-- インデックス追加
CREATE INDEX idx_stripe_account ON drivers(stripe_account_id);
```

**追加カラム数**:
- orders: 8カラム
- restaurants: 5カラム
- drivers: 4カラム
- 合計: **17カラム**

---

## 実装コードの詳細設計

### Step 1: Stripeクライアント初期化

**新規ファイル**: `foodhub-backend/src/config/stripe.js`

```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

module.exports = stripe;
```

---

### Step 2: レストランのStripe Connect登録

**新規ファイル**: `foodhub-backend/src/controllers/stripeConnectController.js`

```javascript
const stripe = require('../config/stripe');
const Restaurant = require('../models/Restaurant');
const Driver = require('../models/Driver');

/**
 * レストランのStripe Connectアカウント作成
 * POST /api/restaurant/stripe/connect
 */
exports.createRestaurantAccount = async (req, res) => {
  try {
    const restaurant_id = req.user.id;
    const restaurant = await Restaurant.findByPk(restaurant_id);

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // 既にアカウントがある場合
    if (restaurant.stripe_account_id) {
      return res.status(400).json({
        error: 'Stripe account already exists',
        account_id: restaurant.stripe_account_id,
      });
    }

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
        url: `https://yourdomain.com/restaurant/${restaurant.id}`,
      },
    });

    // DBに保存
    await restaurant.update({
      stripe_account_id: account.id,
    });

    // オンボーディングリンク作成
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `https://yourdomain.com/restaurant/stripe/refresh`,
      return_url: `https://yourdomain.com/restaurant/stripe/return`,
      type: 'account_onboarding',
    });

    res.json({
      account_id: account.id,
      onboarding_url: accountLink.url,
    });
  } catch (error) {
    console.error('Create restaurant Stripe account error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Stripeオンボーディング完了Webhook
 * POST /webhook/stripe/connect
 */
exports.handleConnectWebhook = async (req, res) => {
  const event = req.body;

  if (event.type === 'account.updated') {
    const account = event.data.object;

    // レストランまたは配達員を更新
    const restaurant = await Restaurant.findOne({
      where: { stripe_account_id: account.id },
    });

    if (restaurant) {
      await restaurant.update({
        stripe_onboarding_completed: account.details_submitted,
        stripe_charges_enabled: account.charges_enabled,
        stripe_payouts_enabled: account.payouts_enabled,
      });
    }

    const driver = await Driver.findOne({
      where: { stripe_account_id: account.id },
    });

    if (driver) {
      await driver.update({
        stripe_onboarding_completed: account.details_submitted,
        stripe_payouts_enabled: account.payouts_enabled,
      });
    }
  }

  res.json({ received: true });
};
```

---

### Step 3: 注文作成時のStripe決済

**変更ファイル**: `foodhub-backend/src/controllers/orderController.js`

**現在の行117-120を置き換え**:

```javascript
// 既存コード（削除）
// const delivery_fee = parseFloat(restaurant.delivery_fee);
// const tax = subtotal * 0.1;
// const total = subtotal + delivery_fee + tax;

// 新しいコード
const delivery_fee = parseFloat(restaurant.delivery_fee);

// サービス料を計算（15%）
const SERVICE_FEE_RATE = 0.15;
const service_fee = Math.round(subtotal * SERVICE_FEE_RATE);

// 税抜き合計
const subtotal_before_tax = subtotal + delivery_fee + service_fee;

// 消費税（10%）
const tax = Math.round(subtotal_before_tax * 0.1);

// 合計
const total = subtotal_before_tax + tax;

// レストラン手数料率（レストラン設定またはデフォルト）
const restaurant_commission_rate = restaurant.commission_rate || 0.35;

// レストラン支払額を事前計算
const restaurant_payout = Math.round(subtotal * (1 - restaurant_commission_rate));

// 配達員支払額（配送料全額 or レストラン設定）
const driver_payout = delivery_fee;

// プラットフォーム収益
const platform_revenue =
  (subtotal - restaurant_payout) +  // レストランマージン
  (delivery_fee - driver_payout) +  // 配送料マージン（0の場合）
  service_fee +                     // サービス料
  tax;                              // 消費税

console.log('[ORDER] Price breakdown:', {
  subtotal,
  delivery_fee,
  service_fee,
  tax,
  total,
  restaurant_payout,
  driver_payout,
  platform_revenue,
});
```

**Order.createの引数に追加**:
```javascript
const order = await Order.create({
  order_number,
  customer_id,
  restaurant_id,
  delivery_address_id,
  status: 'pending',
  subtotal,
  delivery_fee,
  service_fee,              // ← 追加
  tax,
  discount: 0,
  total,
  payment_method,
  restaurant_commission_rate,  // ← 追加
  restaurant_payout,           // ← 追加
  driver_payout,               // ← 追加
  platform_revenue,            // ← 追加
  special_instructions,
  scheduled_at: scheduled_at || null,
}, { transaction });
```

---

### Step 4: Stripe Payment Intent作成

**新規関数**: `orderController.js`

```javascript
const stripe = require('../config/stripe');

/**
 * Create Stripe Payment Intent
 * POST /api/orders/:id/create-payment-intent
 */
exports.createPaymentIntent = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const order = await Order.findOne({
      where: { id, customer_id },
      include: ['restaurant'],
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    if (order.stripe_payment_id) {
      return res.status(400).json({
        error: 'Payment Intent already exists',
        payment_id: order.stripe_payment_id,
      });
    }

    // Payment Intent作成
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(order.total * 100),  // 円 → 銭
      currency: 'jpy',
      payment_method_types: ['card'],
      transfer_group: order.order_number,
      metadata: {
        order_id: order.id,
        customer_id: order.customer_id,
        restaurant_id: order.restaurant_id,
        order_number: order.order_number,
      },
      description: `FoodHub Order ${order.order_number}`,
    });

    // DBに保存
    await order.update({
      stripe_payment_id: paymentIntent.id,
    });

    res.json({
      client_secret: paymentIntent.client_secret,
      publishable_key: process.env.STRIPE_PUBLISHABLE_KEY,
    });
  } catch (error) {
    console.error('Create payment intent error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
```

---

### Step 5: 配達完了時の支払い処理

**新規関数**: `orderController.js`

```javascript
/**
 * Process payouts to restaurant and driver
 * 内部関数（配達完了時に呼ばれる）
 */
async function processOrderPayouts(orderId) {
  try {
    const order = await Order.findByPk(orderId, {
      include: ['restaurant', 'driver'],
    });

    if (!order) {
      throw new Error('Order not found');
    }

    if (order.payout_completed) {
      console.log(`[PAYOUT] Already completed for order ${order.id}`);
      return;
    }

    if (!order.stripe_payment_id) {
      throw new Error('No Stripe payment ID');
    }

    // レストランに支払い
    if (order.restaurant?.stripe_account_id && order.restaurant_payout > 0) {
      const restaurantTransfer = await stripe.transfers.create({
        amount: Math.round(order.restaurant_payout * 100),
        currency: 'jpy',
        destination: order.restaurant.stripe_account_id,
        transfer_group: order.order_number,
        source_transaction: order.stripe_payment_id,
        metadata: {
          order_id: order.id,
          type: 'restaurant_payout',
          original_subtotal: order.subtotal,
          commission_rate: order.restaurant_commission_rate,
        },
        description: `Order ${order.order_number} - Restaurant payout`,
      });

      await order.update({
        stripe_restaurant_transfer_id: restaurantTransfer.id,
      });

      console.log(`[PAYOUT] Restaurant transfer created: ${restaurantTransfer.id}`);
    }

    // 配達員に支払い
    if (order.driver?.stripe_account_id && order.driver_payout > 0) {
      const driverTransfer = await stripe.transfers.create({
        amount: Math.round(order.driver_payout * 100),
        currency: 'jpy',
        destination: order.driver.stripe_account_id,
        transfer_group: order.order_number,
        source_transaction: order.stripe_payment_id,
        metadata: {
          order_id: order.id,
          type: 'driver_payout',
          delivery_fee: order.delivery_fee,
        },
        description: `Order ${order.order_number} - Driver payout`,
      });

      await order.update({
        stripe_driver_transfer_id: driverTransfer.id,
      });

      console.log(`[PAYOUT] Driver transfer created: ${driverTransfer.id}`);
    }

    // 支払い完了フラグを立てる
    await order.update({
      payout_completed: true,
    });

    console.log(`[PAYOUT] Completed for order ${order.id}`);
  } catch (error) {
    console.error('[PAYOUT] Error:', error);
    throw error;
  }
}

/**
 * Update delivery status（既存関数を拡張）
 */
exports.updateDeliveryStatus = async (req, res) => {
  // 既存のコード...

  // 配達完了時に支払い処理を実行
  if (status === 'delivered' && order.payment_method === 'card') {
    // 非同期で実行（レスポンスを待たせない）
    processOrderPayouts(order.id).catch(err => {
      console.error('Payout processing failed:', err);
    });
  }

  // 既存のレスポンス...
};
```

---

### Step 6: Flutter側の実装

#### 6-1. OrderModelにフィールド追加

**変更ファイル**: `food_hub/lib/shared/models/order_model.dart`

```dart
@JsonSerializable()
class OrderModel {
  final int id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  // ... 既存フィールド ...

  final double subtotal;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'service_fee')     // ← 追加
  final double serviceFee;
  final double tax;
  final double discount;
  final double total;

  // ... 以下既存 ...
}
```

#### 6-2. CartProviderの計算ロジック修正

**変更ファイル**: `food_hub/lib/features/customer/providers/cart_provider.dart`

```dart
// 既存のsubtotal, taxは維持

// サービス料を追加
double get serviceFee {
  const SERVICE_FEE_RATE = 0.15;  // 15%
  return subtotal * SERVICE_FEE_RATE;
}

// 税の計算を修正
double get tax {
  final subtotalBeforeTax = subtotal + deliveryFee + serviceFee;
  return subtotalBeforeTax * 0.1;  // 10%
}

// 合計の計算を修正
double get total {
  return subtotal + deliveryFee + serviceFee + tax;
}
```

#### 6-3. Stripe決済画面の作成

**新規ファイル**: `food_hub/lib/features/customer/screens/stripe_payment_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StripePaymentScreen extends ConsumerStatefulWidget {
  final int orderId;
  final double amount;

  const StripePaymentScreen({
    required this.orderId,
    required this.amount,
    super.key,
  });

  @override
  ConsumerState<StripePaymentScreen> createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends ConsumerState<StripePaymentScreen> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 1. Payment Intent作成APIを呼ぶ
      final response = await createPaymentIntentApi(widget.orderId);

      // 2. Stripe初期化
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'FoodHub',
          paymentIntentClientSecret: response.clientSecret,
          style: ThemeMode.light,
        ),
      );

      // 3. Payment Sheetを表示
      await Stripe.instance.presentPaymentSheet();

      // 4. 成功
      if (mounted) {
        Navigator.of(context).pop(true);  // 成功を返す
      }
    } on StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('決済エラー: ${e.error.message}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('お支払い')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('お支払い金額: ¥${widget.amount.toInt()}'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? CircularProgressIndicator()
                  : Text('カードで支払う'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 実装フェーズ計画

### Phase 1: データベース変更（必須）

**所要時間**: 10分

1. マイグレーションSQL実行
2. テーブル構造確認

**成果物**:
- 17カラム追加完了

---

### Phase 2: バックエンド実装（コア機能）

**所要時間**: 4-5時間

1. Stripe設定ファイル作成（10分）
2. Connect Account作成API（1時間）
3. 注文作成ロジック修正（1時間）
4. Payment Intent作成API（30分）
5. Payout処理実装（1時間）
6. Webhook実装（30分）
7. ルート追加（30分）

**成果物**:
- 3ファイル新規作成
- 2ファイル変更

---

### Phase 3: Flutter実装（UI）

**所要時間**: 3-4時間

1. OrderModel更新（30分）
2. CartProvider修正（30分）
3. Stripe決済画面作成（1時間）
4. チェックアウトフロー統合（1時間）
5. エラーハンドリング（30分）
6. テスト（30分）

**成果物**:
- 2ファイル新規作成
- 3ファイル変更

---

### Phase 4: テスト（重要）

**所要時間**: 2-3時間

1. Stripeテストモード設定
2. レストランConnect登録テスト
3. 配達員Connect登録テスト
4. 決済フローテスト
5. Payout処理テスト
6. Webhookテスト

---

## 実装可能性の最終判定

### ✅ 完全に実装可能

**理由**:
1. Stripe SDKインストール済み（バックエンド・Flutter両方）
2. 基本テーブル構造が存在
3. 注文作成フローが既に実装済み
4. 必要なのはカラム追加と支払いロジック追加のみ

### 必要な作業の全リスト

**データベース**:
- [ ] 17カラム追加（1つのSQLファイル）

**バックエンド（Node.js）**:
- [ ] stripe.js 設定ファイル作成
- [ ] stripeConnectController.js 作成
- [ ] orderController.js の計算ロジック修正
- [ ] Payment Intent API追加
- [ ] Payout処理実装
- [ ] Webhook実装
- [ ] ルート追加

**フロントエンド（Flutter）**:
- [ ] OrderModel にservice_fee追加
- [ ] CartProvider の計算修正
- [ ] Stripe決済画面作成
- [ ] チェックアウトフロー修正

**設定**:
- [ ] Stripe APIキーを本番キーに変更
- [ ] Webhook URL設定

**テスト**:
- [ ] Connect登録テスト
- [ ] 決済テスト
- [ ] Payoutテスト

---

## 推定工数

| フェーズ | 所要時間 |
|---------|---------|
| DB変更 | 10分 |
| バックエンド | 4-5時間 |
| Flutter | 3-4時間 |
| テスト | 2-3時間 |
| **合計** | **9-12時間** |

---

## リスクと注意事項

### リスク1: Stripeオンボーディング

レストラン・配達員が実際にStripeアカウントを作成する必要がある
- 本人確認書類
- 銀行口座情報
- 所要時間: 10-30分/人

### リスク2: 転送タイミング

標準転送は1-2日かかる
- Instant Payout使用で即時化可能（手数料1%追加）

### リスク3: 本番環境への移行

テストモードと本番モードで別のAPIキーが必要

---

## 結論

**実装可能**: ✅ 完全に可能

**最小限の実装**:
- 6カラム追加のみで基本機能は動く
- 推定6-8時間

**完全実装**:
- 17カラム追加
- 推定9-12時間

**推奨**: 完全実装（将来の拡張性を考慮）

この計画で実装を開始してよろしいでしょうか？
