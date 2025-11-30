# サーバー側作業リスト - Stripe設定必須化

作成日: 2025-11-30
対象サーバー: 133.117.77.23

---

## 前提条件

このファイルに記載されている作業は**すべてサーバー側（133.117.77.23）で実施**する必要があります。
Flutter側の作業は `CLIENT_SIDE_TASKS.md` を参照してください。

---

## 作業1: データベースマイグレーション（必須）

### 概要
`DB_MIGRATION_STRIPE.md` に記載されているSQLを実行して、必要なカラムを追加します。

### 手順

#### Step 1: サーバーにSSH接続
```bash
ssh user@133.117.77.23
```

#### Step 2: MySQLにログイン
```bash
mysql -u foodhub_user -p foodhub
# パスワード: FoodHub2024Secure!
```

#### Step 3: SQLを実行

**restaurantsテーブルに5カラム追加**:
```sql
USE foodhub;

-- Stripe Connect Account ID
ALTER TABLE restaurants
ADD COLUMN stripe_account_id VARCHAR(255) NULL
AFTER is_approved
COMMENT 'Stripe Connect Account ID（支払い受取用）';

-- Stripeオンボーディング完了
ALTER TABLE restaurants
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE
AFTER stripe_account_id
COMMENT 'Stripeの本人確認・銀行口座登録が完了したか';

-- Stripe決済受付可能
ALTER TABLE restaurants
ADD COLUMN stripe_charges_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_onboarding_completed
COMMENT 'Stripe決済を受け付けられる状態か';

-- Stripe支払い受取可能
ALTER TABLE restaurants
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_charges_enabled
COMMENT 'Stripe支払いを受け取れる状態か';

-- プラットフォーム手数料率
ALTER TABLE restaurants
ADD COLUMN commission_rate DECIMAL(5,4) DEFAULT 0.35
AFTER stripe_payouts_enabled
COMMENT 'プラットフォーム手数料率（例: 0.35 = 35%）';

-- インデックス追加
CREATE INDEX idx_stripe_account ON restaurants(stripe_account_id);
CREATE INDEX idx_stripe_onboarding ON restaurants(stripe_onboarding_completed);
```

**driversテーブルに4カラム追加**:
```sql
-- Stripe Connect Account ID
ALTER TABLE drivers
ADD COLUMN stripe_account_id VARCHAR(255) NULL
AFTER bank_account_info
COMMENT 'Stripe Connect Account ID（報酬受取用）';

-- Stripeオンボーディング完了
ALTER TABLE drivers
ADD COLUMN stripe_onboarding_completed BOOLEAN DEFAULT FALSE
AFTER stripe_account_id
COMMENT 'Stripeの本人確認・銀行口座登録が完了したか';

-- Stripe支払い受取可能
ALTER TABLE drivers
ADD COLUMN stripe_payouts_enabled BOOLEAN DEFAULT FALSE
AFTER stripe_onboarding_completed
COMMENT 'Stripe支払いを受け取れる状態か';

-- 配達1件あたりの基本報酬
ALTER TABLE drivers
ADD COLUMN base_payout_per_delivery DECIMAL(10,2) DEFAULT 400.00
AFTER stripe_payouts_enabled
COMMENT '配達1件あたりの基本報酬（デフォルト¥400）';

-- インデックス追加
CREATE INDEX idx_stripe_account ON drivers(stripe_account_id);
CREATE INDEX idx_stripe_onboarding ON drivers(stripe_onboarding_completed);
```

#### Step 4: 実行結果の確認
```sql
-- restaurantsテーブルの確認
DESCRIBE restaurants;

-- 以下が表示されることを確認:
-- stripe_account_id             | varchar(255)
-- stripe_onboarding_completed   | tinyint(1)
-- stripe_charges_enabled        | tinyint(1)
-- stripe_payouts_enabled        | tinyint(1)
-- commission_rate               | decimal(5,4)

-- driversテーブルの確認
DESCRIBE drivers;

-- 以下が表示されることを確認:
-- stripe_account_id             | varchar(255)
-- stripe_onboarding_completed   | tinyint(1)
-- stripe_payouts_enabled        | tinyint(1)
-- base_payout_per_delivery      | decimal(10,2)

-- インデックスの確認
SHOW INDEXES FROM restaurants WHERE Key_name LIKE 'idx_stripe%';
SHOW INDEXES FROM drivers WHERE Key_name LIKE 'idx_stripe%';
```

---

## 作業2: バックエンドAPI実装（必須）

### 2-1. GET /api/restaurant/profile

#### 目的
レストラン自身の情報（Stripe状態を含む）を取得するAPI

#### エンドポイント
```
GET /api/restaurant/profile
```

#### リクエストヘッダー
```
Authorization: Bearer <restaurant_token>
```

#### レスポンス例（JSON）
```json
{
  "id": 1,
  "name": "レストランA",
  "description": "美味しい料理を提供します",
  "image_url": "https://example.com/restaurant.jpg",
  "is_approved": true,
  "stripe_account_id": "acct_1234567890",
  "stripe_onboarding_completed": true,
  "stripe_charges_enabled": true,
  "stripe_payouts_enabled": true,
  "commission_rate": 0.35,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

#### 実装箇所（想定）
**ファイル**: `foodhub-backend/src/controllers/restaurantController.js`

**追加するコード例**:
```javascript
// GET /api/restaurant/profile
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id; // JWTから取得

    // レストラン情報を取得
    const restaurant = await Restaurant.findOne({
      where: { user_id: userId }
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // レスポンス
    res.json({
      id: restaurant.id,
      name: restaurant.name,
      description: restaurant.description,
      image_url: restaurant.image_url,
      is_approved: restaurant.is_approved,
      stripe_account_id: restaurant.stripe_account_id,
      stripe_onboarding_completed: restaurant.stripe_onboarding_completed,
      stripe_charges_enabled: restaurant.stripe_charges_enabled,
      stripe_payouts_enabled: restaurant.stripe_payouts_enabled,
      commission_rate: restaurant.commission_rate,
      created_at: restaurant.created_at,
      updated_at: restaurant.updated_at,
    });
  } catch (error) {
    console.error('Get restaurant profile error:', error);
    res.status(500).json({ error: 'Failed to get restaurant profile' });
  }
};
```

#### ルート追加（想定）
**ファイル**: `foodhub-backend/src/routes/restaurantRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const restaurantController = require('../controllers/restaurantController');
const { authenticateToken, requireRestaurant } = require('../middleware/auth');

// 既存ルート...

// レストランプロフィール取得
router.get('/profile', authenticateToken, requireRestaurant, restaurantController.getProfile);

module.exports = router;
```

---

### 2-2. GET /api/driver/profile

#### 目的
配達員自身の情報（Stripe状態を含む）を取得するAPI

#### エンドポイント
```
GET /api/driver/profile
```

#### リクエストヘッダー
```
Authorization: Bearer <driver_token>
```

#### レスポンス例（JSON）
```json
{
  "id": 1,
  "full_name": "配達員太郎",
  "phone": "090-1234-5678",
  "vehicle_type": "bike",
  "license_plate": "東京 あ 1234",
  "is_online": false,
  "stripe_account_id": "acct_9876543210",
  "stripe_onboarding_completed": true,
  "stripe_payouts_enabled": true,
  "base_payout_per_delivery": 400.00,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

#### 実装箇所（想定）
**ファイル**: `foodhub-backend/src/controllers/driverController.js`

**追加するコード例**:
```javascript
// GET /api/driver/profile
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id; // JWTから取得

    // 配達員情報を取得
    const driver = await Driver.findOne({
      where: { user_id: userId }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    // レスポンス
    res.json({
      id: driver.id,
      full_name: driver.full_name,
      phone: driver.phone,
      vehicle_type: driver.vehicle_type,
      license_plate: driver.license_plate,
      is_online: driver.is_online,
      stripe_account_id: driver.stripe_account_id,
      stripe_onboarding_completed: driver.stripe_onboarding_completed,
      stripe_payouts_enabled: driver.stripe_payouts_enabled,
      base_payout_per_delivery: driver.base_payout_per_delivery,
      created_at: driver.created_at,
      updated_at: driver.updated_at,
    });
  } catch (error) {
    console.error('Get driver profile error:', error);
    res.status(500).json({ error: 'Failed to get driver profile' });
  }
};
```

#### ルート追加（想定）
**ファイル**: `foodhub-backend/src/routes/driverRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const driverController = require('../controllers/driverController');
const { authenticateToken, requireDriver } = require('../middleware/auth');

// 既存ルート...

// 配達員プロフィール取得
router.get('/profile', authenticateToken, requireDriver, driverController.getProfile);

module.exports = router;
```

---

## 作業3: バックエンドバリデーション追加（オプション）

### 概要
Flutter側でもチェックしますが、サーバー側でも二重チェックすることでセキュリティ向上。

### 3-1. メニュー追加APIにバリデーション追加

**ファイル**: `foodhub-backend/src/controllers/menuController.js`

**修正箇所**: `createMenuItem` 関数

**追加するコード**:
```javascript
exports.createMenuItem = async (req, res) => {
  try {
    const userId = req.user.id;

    // レストラン情報を取得
    const restaurant = await Restaurant.findOne({
      where: { user_id: userId }
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // ★ Stripe設定チェック（追加）
    if (!restaurant.stripe_onboarding_completed || !restaurant.stripe_payouts_enabled) {
      return res.status(403).json({
        error: 'Stripe setup required',
        message: 'Stripe登録を完了してください。設定画面から登録できます。'
      });
    }

    // 既存のメニュー作成処理...
  } catch (error) {
    console.error('Create menu item error:', error);
    res.status(500).json({ error: 'Failed to create menu item' });
  }
};
```

---

### 3-2. 配達受付APIにバリデーション追加

**ファイル**: `foodhub-backend/src/controllers/orderController.js`

**修正箇所**: `acceptDelivery` 関数（配達員が配達を受け付ける処理）

**追加するコード**:
```javascript
exports.acceptDelivery = async (req, res) => {
  try {
    const userId = req.user.id;
    const { orderId } = req.params;

    // 配達員情報を取得
    const driver = await Driver.findOne({
      where: { user_id: userId }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    // ★ Stripe設定チェック（追加）
    if (!driver.stripe_onboarding_completed || !driver.stripe_payouts_enabled) {
      return res.status(403).json({
        error: 'Stripe setup required',
        message: 'Stripe登録を完了してください。設定画面から登録できます。'
      });
    }

    // 既存の配達受付処理...
  } catch (error) {
    console.error('Accept delivery error:', error);
    res.status(500).json({ error: 'Failed to accept delivery' });
  }
};
```

---

### 3-3. オンライン切替APIにバリデーション追加

**ファイル**: `foodhub-backend/src/controllers/driverController.js`

**修正箇所**: `toggleOnlineStatus` 関数

**追加するコード**:
```javascript
exports.toggleOnlineStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const { is_online } = req.body;

    // 配達員情報を取得
    const driver = await Driver.findOne({
      where: { user_id: userId }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    // ★ オンラインにする場合のみStripe設定チェック（追加）
    if (is_online && (!driver.stripe_onboarding_completed || !driver.stripe_payouts_enabled)) {
      return res.status(403).json({
        error: 'Stripe setup required',
        message: 'Stripe登録を完了してください。設定画面から登録できます。'
      });
    }

    // 既存のオンライン状態更新処理...
  } catch (error) {
    console.error('Toggle online status error:', error);
    res.status(500).json({ error: 'Failed to toggle online status' });
  }
};
```

---

## 作業4: サーバー再起動（必須）

### 概要
コード変更後、Node.jsサーバーを再起動して変更を反映します。

### 手順

#### PM2を使用している場合
```bash
pm2 restart foodhub-backend
pm2 logs foodhub-backend --lines 50
```

#### 直接起動している場合
```bash
# 既存プロセスを停止
pkill -f "node.*server.js"

# 再起動
cd /path/to/foodhub-backend
nohup node src/server.js > server.log 2>&1 &
```

---

## 作業チェックリスト

実施後、以下を確認してください:

### データベース
- [ ] `restaurants` テーブルに5カラム追加されている
- [ ] `drivers` テーブルに4カラム追加されている
- [ ] インデックスが作成されている（4つ）
- [ ] 既存データが壊れていない（SELECT文で確認）

### API実装
- [ ] `GET /api/restaurant/profile` が実装されている
- [ ] `GET /api/driver/profile` が実装されている
- [ ] レスポンスにStripe関連フィールドが含まれている

### バリデーション（オプション）
- [ ] メニュー追加APIにStripe設定チェックが追加されている
- [ ] 配達受付APIにStripe設定チェックが追加されている
- [ ] オンライン切替APIにStripe設定チェックが追加されている

### サーバー
- [ ] Node.jsサーバーが正常に再起動している
- [ ] エラーログが出ていない

---

## テスト手順

### テスト1: GET /api/restaurant/profile

**curlでテスト**:
```bash
curl -X GET https://133-117-77-23.nip.io/api/restaurant/profile \
  -H "Authorization: Bearer <restaurant_token>" \
  -H "Content-Type: application/json"
```

**期待されるレスポンス**:
```json
{
  "id": 1,
  "name": "...",
  "stripe_account_id": null,
  "stripe_onboarding_completed": false,
  "stripe_payouts_enabled": false,
  ...
}
```

---

### テスト2: GET /api/driver/profile

**curlでテスト**:
```bash
curl -X GET https://133-117-77-23.nip.io/api/driver/profile \
  -H "Authorization: Bearer <driver_token>" \
  -H "Content-Type: application/json"
```

**期待されるレスポンス**:
```json
{
  "id": 1,
  "full_name": "...",
  "stripe_account_id": null,
  "stripe_onboarding_completed": false,
  "stripe_payouts_enabled": false,
  ...
}
```

---

## ロールバック手順（問題発生時）

### データベースロールバック
```sql
USE foodhub;

-- インデックス削除
DROP INDEX idx_stripe_account ON restaurants;
DROP INDEX idx_stripe_onboarding ON restaurants;
DROP INDEX idx_stripe_account ON drivers;
DROP INDEX idx_stripe_onboarding ON drivers;

-- カラム削除
ALTER TABLE restaurants DROP COLUMN commission_rate;
ALTER TABLE restaurants DROP COLUMN stripe_payouts_enabled;
ALTER TABLE restaurants DROP COLUMN stripe_charges_enabled;
ALTER TABLE restaurants DROP COLUMN stripe_onboarding_completed;
ALTER TABLE restaurants DROP COLUMN stripe_account_id;

ALTER TABLE drivers DROP COLUMN base_payout_per_delivery;
ALTER TABLE drivers DROP COLUMN stripe_payouts_enabled;
ALTER TABLE drivers DROP COLUMN stripe_onboarding_completed;
ALTER TABLE drivers DROP COLUMN stripe_account_id;
```

### コードロールバック
```bash
cd /path/to/foodhub-backend
git reset --hard HEAD~1  # 直前のコミットに戻す
pm2 restart foodhub-backend
```

---

## 実施記録

```
実施日時: _______________
実施者: _______________
実行環境: 本番サーバー（133.117.77.23）

【データベースマイグレーション】
実行結果: □ 成功 / □ 失敗
追加カラム数: 9カラム（restaurants: 5, drivers: 4）
実行時間: _____ 秒

【API実装】
実装API数: 2つ
テスト結果: □ 成功 / □ 失敗

【バリデーション追加】
追加箇所: 3箇所
実装: □ 完了 / □ スキップ

【サーバー再起動】
再起動: □ 成功 / □ 失敗

エラー内容（失敗時）: _______________________
備考: _______________________________________
```

---

## 次のステップ

サーバー側作業完了後:

1. Flutter側の実装を開始（`CLIENT_SIDE_TASKS.md` 参照）
2. 統合テスト実施
3. 本番環境デプロイ

---

このファイルを参照しながら、サーバー側作業を実施してください。
