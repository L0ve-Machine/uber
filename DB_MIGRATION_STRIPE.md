# Stripe決済機能 データベース変更手順書

実施予定日: TBD
対象サーバー: 133.117.77.23
対象DB: foodhub

---

## 変更概要

Stripe決済とマーケットプレイス機能を実装するため、3つのテーブルに**合計17カラム**を追加します。

---

## 実行するSQL

### リモートサーバー（133.117.77.23）で実行

```sql
USE foodhub;

-- ================================================
-- ordersテーブル: 8カラム追加
-- ================================================

-- サービス料（プラットフォーム収益）
ALTER TABLE orders
ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0.00
AFTER delivery_fee
COMMENT 'サービス料（注文額の15%）';

-- レストラン手数料率
ALTER TABLE orders
ADD COLUMN restaurant_commission_rate DECIMAL(5,4) DEFAULT 0.35
AFTER service_fee
COMMENT 'レストラン手数料率（デフォルト35% = 0.35）';

-- レストラン支払額
ALTER TABLE orders
ADD COLUMN restaurant_payout DECIMAL(10,2) NULL
AFTER restaurant_commission_rate
COMMENT 'レストランへの実際の支払額（商品代 × (1-手数料率)）';

-- 配達員支払額
ALTER TABLE orders
ADD COLUMN driver_payout DECIMAL(10,2) NULL
AFTER restaurant_payout
COMMENT '配達員への実際の支払額（通常は配送料全額）';

-- プラットフォーム収益
ALTER TABLE orders
ADD COLUMN platform_revenue DECIMAL(10,2) NULL
AFTER driver_payout
COMMENT 'プラットフォームの総収益（手数料+サービス料+税）';

-- Stripe Transfer ID（レストラン）
ALTER TABLE orders
ADD COLUMN stripe_restaurant_transfer_id VARCHAR(255) NULL
AFTER stripe_payment_id
COMMENT 'Stripe Transfer ID（レストランへの送金記録）';

-- Stripe Transfer ID（配達員）
ALTER TABLE orders
ADD COLUMN stripe_driver_transfer_id VARCHAR(255) NULL
AFTER stripe_restaurant_transfer_id
COMMENT 'Stripe Transfer ID（配達員への送金記録）';

-- 支払い完了フラグ
ALTER TABLE orders
ADD COLUMN payout_completed BOOLEAN DEFAULT FALSE
AFTER platform_revenue
COMMENT 'レストラン・配達員への支払いが完了したか';

-- ================================================
-- restaurantsテーブル: 5カラム追加
-- ================================================

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

-- プラットフォーム手数料率（レストランごとに設定可能）
ALTER TABLE restaurants
ADD COLUMN commission_rate DECIMAL(5,4) DEFAULT 0.35
AFTER stripe_payouts_enabled
COMMENT 'プラットフォーム手数料率（例: 0.35 = 35%、0.20 = 20%）';

-- インデックス追加（検索高速化）
CREATE INDEX idx_stripe_account ON restaurants(stripe_account_id);
CREATE INDEX idx_stripe_onboarding ON restaurants(stripe_onboarding_completed);

-- ================================================
-- driversテーブル: 4カラム追加
-- ================================================

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

---

## 各カラムの詳細説明

### ordersテーブルの新規カラム

#### 1. service_fee（サービス料）

**目的**: プラットフォームが顧客から徴収するサービス料

**計算式**: `subtotal × 0.15`（商品代の15%）

**例**:
```
商品代: ¥2,000
サービス料: ¥2,000 × 0.15 = ¥300
```

**使用タイミング**: 注文作成時に自動計算

---

#### 2. restaurant_commission_rate（レストラン手数料率）

**目的**: このレストランから徴収する手数料率

**デフォルト値**: 0.35（35%）

**使用例**:
```
商品代: ¥2,000
手数料率: 0.35（35%）
プラットフォームが取る: ¥2,000 × 0.35 = ¥700
レストランが受け取る: ¥2,000 × 0.65 = ¥1,300
```

**カスタマイズ可能**: レストランごとに異なる率を設定できる
- 大手チェーン: 0.20（20%）
- 小規模店舗: 0.35（35%）

---

#### 3. restaurant_payout（レストラン支払額）

**目的**: レストランに実際に送金する金額

**計算式**: `subtotal × (1 - restaurant_commission_rate)`

**例**:
```
商品代: ¥2,000
手数料率: 0.35
レストラン支払額: ¥2,000 × (1 - 0.35) = ¥1,300
```

**NULL許可**: 計算前はNULL、配達完了時に計算

---

#### 4. driver_payout（配達員支払額）

**目的**: 配達員に実際に送金する金額

**計算式**: 通常は `delivery_fee`（配送料全額）

**例**:
```
配送料: ¥400
配達員支払額: ¥400（全額）
```

**または固定額**:
```
配達員支払額: ¥400（base_payout_per_deliveryから）
```

---

#### 5. platform_revenue（プラットフォーム収益）

**目的**: プラットフォームの総収益（分析用）

**計算式**:
```
レストランマージン + 配送料マージン + サービス料 + 消費税
```

**例**:
```
(¥2,000 - ¥1,300) + (¥400 - ¥400) + ¥300 + ¥270
= ¥700 + ¥0 + ¥300 + ¥270
= ¥1,270
```

**用途**: 収益レポート、ダッシュボード表示

---

#### 6-7. stripe_restaurant_transfer_id / stripe_driver_transfer_id

**目的**: Stripe Transfer APIのレスポンスIDを保存

**形式**: `tr_xxxxxxxxxx`

**用途**:
- 送金履歴の追跡
- 返金処理
- トラブルシューティング

---

#### 8. payout_completed（支払い完了フラグ）

**目的**: レストラン・配達員への支払いが完了したか

**値**:
- FALSE: 未払い
- TRUE: 支払い完了

**使用タイミング**:
- 配達完了時にTRUEに設定
- キャンセル時の返金判定に使用

---

### restaurantsテーブルの新規カラム

#### 1. stripe_account_id（Stripe Account ID）

**目的**: このレストランのStripe Connect Account ID

**形式**: `acct_xxxxxxxxxx`

**設定タイミング**: レストラン登録時にStripe APIで作成

**例**: `acct_1KP8JM2ROgShXwm9`

**用途**: 支払い時の送金先指定

---

#### 2. stripe_onboarding_completed（オンボーディング完了）

**目的**: Stripeの本人確認・銀行口座登録が完了したか

**値**:
- FALSE: 未完了（支払い受取不可）
- TRUE: 完了（支払い受取可能）

**設定タイミング**: Stripe Webhookで自動更新

---

#### 3-4. stripe_charges_enabled / stripe_payouts_enabled

**目的**: Stripeアカウントの状態確認

**用途**:
- charges_enabled: 決済を受け付けられるか
- payouts_enabled: 支払いを受け取れるか

**設定タイミング**: Stripe Webhookで自動更新

---

#### 5. commission_rate（手数料率）

**目的**: このレストランの手数料率

**デフォルト**: 0.35（35%）

**カスタマイズ例**:
```sql
-- 大手チェーンは20%に優遇
UPDATE restaurants
SET commission_rate = 0.20
WHERE id = 1;

-- 新規店舗は35%
UPDATE restaurants
SET commission_rate = 0.35
WHERE id = 2;
```

---

### driversテーブルの新規カラム

#### 1. stripe_account_id（Stripe Account ID）

**目的**: この配達員のStripe Connect Account ID

**形式**: `acct_xxxxxxxxxx`

**設定タイミング**: 配達員登録時にStripe APIで作成

---

#### 2-3. stripe_onboarding_completed / stripe_payouts_enabled

**目的**: レストランと同じ

---

#### 4. base_payout_per_delivery（基本報酬）

**目的**: 配達1件あたりの基本報酬

**デフォルト**: 400.00（¥400）

**用途**:
- 配達員への支払い額計算
- 配送料と異なる場合に使用

**例**:
```
配送料（顧客が払う）: ¥500
配達員報酬: ¥400（base_payout_per_delivery）
差額: ¥100 → プラットフォームのマージン
```

---

## 実行手順

### Step 1: サーバーにSSH接続

```bash
ssh user@133.117.77.23
```

---

### Step 2: MySQLにログイン

```bash
mysql -u foodhub_user -p foodhub
# パスワード: FoodHub2024Secure!
```

---

### Step 3: マイグレーション実行

上記のSQLを順番にコピペして実行してください。

**推奨**: 1つずつ実行して結果を確認

---

### Step 4: 実行結果の確認

```sql
-- ordersテーブルの確認
DESCRIBE orders;

-- 以下が表示されることを確認:
-- service_fee                   | decimal(10,2)
-- restaurant_commission_rate    | decimal(5,4)
-- restaurant_payout             | decimal(10,2)
-- driver_payout                 | decimal(10,2)
-- platform_revenue              | decimal(10,2)
-- stripe_restaurant_transfer_id | varchar(255)
-- stripe_driver_transfer_id     | varchar(255)
-- payout_completed              | tinyint(1)

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

## 各カラムの使用例

### 注文作成時の計算例

```
【顧客の支払い】
商品代（subtotal）: ¥2,000
配送料（delivery_fee）: ¥400
サービス料（service_fee）: ¥300（商品代の15%）
小計: ¥2,700
消費税（tax）: ¥270（小計の10%）
合計（total）: ¥2,970

【データベースに保存される値】
subtotal: 2000.00
delivery_fee: 400.00
service_fee: 300.00
tax: 270.00
total: 2970.00

restaurant_commission_rate: 0.3500（35%）
restaurant_payout: 1300.00（¥2,000 × 0.65）
driver_payout: 400.00（配送料全額）
platform_revenue: 1270.00（¥700 + ¥0 + ¥300 + ¥270）

stripe_payment_id: pi_xxxxxxxxxxxxx（顧客からの決済ID）
stripe_restaurant_transfer_id: NULL（配達完了後に設定）
stripe_driver_transfer_id: NULL（配達完了後に設定）
payout_completed: FALSE（配達完了後にTRUE）
```

---

### 配達完了時の更新例

```sql
-- 配達完了時にTransfer IDと完了フラグを更新
UPDATE orders
SET
  stripe_restaurant_transfer_id = 'tr_1Abc2Def3Ghi',
  stripe_driver_transfer_id = 'tr_1Xyz9Uvw8Rst',
  payout_completed = TRUE
WHERE id = 123;
```

---

## 変更前後のテーブル構造比較

### ordersテーブル

**変更前**:
```sql
subtotal DECIMAL(10,2)
delivery_fee DECIMAL(10,2)
tax DECIMAL(10,2)
total DECIMAL(10,2)
stripe_payment_id VARCHAR(255)
```

**変更後**:
```sql
subtotal DECIMAL(10,2)
delivery_fee DECIMAL(10,2)
service_fee DECIMAL(10,2)                    -- ★ 新規
restaurant_commission_rate DECIMAL(5,4)      -- ★ 新規
restaurant_payout DECIMAL(10,2)              -- ★ 新規
driver_payout DECIMAL(10,2)                  -- ★ 新規
platform_revenue DECIMAL(10,2)               -- ★ 新規
tax DECIMAL(10,2)
total DECIMAL(10,2)
stripe_payment_id VARCHAR(255)
stripe_restaurant_transfer_id VARCHAR(255)   -- ★ 新規
stripe_driver_transfer_id VARCHAR(255)       -- ★ 新規
payout_completed BOOLEAN                     -- ★ 新規
```

---

### restaurantsテーブル

**変更前**:
```sql
is_approved BOOLEAN
created_at TIMESTAMP
updated_at TIMESTAMP
```

**変更後**:
```sql
is_approved BOOLEAN
stripe_account_id VARCHAR(255)               -- ★ 新規
stripe_onboarding_completed BOOLEAN          -- ★ 新規
stripe_charges_enabled BOOLEAN               -- ★ 新規
stripe_payouts_enabled BOOLEAN               -- ★ 新規
commission_rate DECIMAL(5,4)                 -- ★ 新規
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

### driversテーブル

**変更前**:
```sql
bank_account_info JSON
created_at TIMESTAMP
updated_at TIMESTAMP
```

**変更後**:
```sql
bank_account_info JSON
stripe_account_id VARCHAR(255)               -- ★ 新規
stripe_onboarding_completed BOOLEAN          -- ★ 新規
stripe_payouts_enabled BOOLEAN               -- ★ 新規
base_payout_per_delivery DECIMAL(10,2)       -- ★ 新規
created_at TIMESTAMP
updated_at TIMESTAMP
```

---

## データ整合性チェック

### 既存データの確認

マイグレーション実行後、既存の注文データを確認:

```sql
-- 既存注文の新規カラムはすべてデフォルト値またはNULL
SELECT
  id,
  order_number,
  service_fee,           -- 0.00
  restaurant_payout,     -- NULL
  payout_completed       -- FALSE
FROM orders
LIMIT 5;
```

**期待される結果**:
- service_fee: 0.00（既存注文はサービス料なし）
- restaurant_payout: NULL（未計算）
- payout_completed: FALSE（未払い）

**問題なし**: 既存注文には影響しない

---

### 既存レストラン・配達員の確認

```sql
-- 既存レストランのStripe情報はすべてNULLまたはFALSE
SELECT
  id,
  name,
  stripe_account_id,              -- NULL
  stripe_onboarding_completed,    -- FALSE
  commission_rate                 -- 0.3500
FROM restaurants
LIMIT 5;

-- 既存配達員のStripe情報はすべてNULLまたはFALSE
SELECT
  id,
  full_name,
  stripe_account_id,              -- NULL
  stripe_onboarding_completed,    -- FALSE
  base_payout_per_delivery        -- 400.00
FROM drivers
LIMIT 5;
```

**期待される結果**: すべてデフォルト値

---

## 影響範囲の分析

### アプリケーションへの影響

**後方互換性**: ✅ 完全に維持

- 既存の現金支払いは引き続き動作
- 新規カラムはすべてデフォルト値あり
- 既存APIは変更なしで動作

**新機能**:
- Stripe決済が有効化される
- レストラン・配達員への自動送金が可能に

---

## ロールバック手順（問題発生時）

```sql
USE foodhub;

-- インデックス削除
DROP INDEX idx_stripe_account ON restaurants;
DROP INDEX idx_stripe_onboarding ON restaurants;
DROP INDEX idx_stripe_account ON drivers;
DROP INDEX idx_stripe_onboarding ON drivers;

-- ordersテーブルのカラム削除
ALTER TABLE orders DROP COLUMN payout_completed;
ALTER TABLE orders DROP COLUMN stripe_driver_transfer_id;
ALTER TABLE orders DROP COLUMN stripe_restaurant_transfer_id;
ALTER TABLE orders DROP COLUMN platform_revenue;
ALTER TABLE orders DROP COLUMN driver_payout;
ALTER TABLE orders DROP COLUMN restaurant_payout;
ALTER TABLE orders DROP COLUMN restaurant_commission_rate;
ALTER TABLE orders DROP COLUMN service_fee;

-- restaurantsテーブルのカラム削除
ALTER TABLE restaurants DROP COLUMN commission_rate;
ALTER TABLE restaurants DROP COLUMN stripe_payouts_enabled;
ALTER TABLE restaurants DROP COLUMN stripe_charges_enabled;
ALTER TABLE restaurants DROP COLUMN stripe_onboarding_completed;
ALTER TABLE restaurants DROP COLUMN stripe_account_id;

-- driversテーブルのカラム削除
ALTER TABLE drivers DROP COLUMN base_payout_per_delivery;
ALTER TABLE drivers DROP COLUMN stripe_payouts_enabled;
ALTER TABLE drivers DROP COLUMN stripe_onboarding_completed;
ALTER TABLE drivers DROP COLUMN stripe_account_id;
```

警告: カラム削除はデータ消失を伴います。

---

## 実施チェックリスト

実施後、以下を確認してください:

- [ ] ordersテーブルに8カラム追加されている
- [ ] restaurantsテーブルに5カラム追加されている
- [ ] driversテーブルに4カラム追加されている
- [ ] 4つのインデックスが作成されている
- [ ] 既存データが壊れていない
- [ ] 既存のアプリケーション機能が正常動作する

---

## 実施記録

```
実施日時: _______________
実施者: _______________
実行環境: 本番DB（133.117.77.23）
実行結果: □ 成功 / □ 失敗
追加カラム数: 17カラム
実行時間: _____ 秒
エラー内容（失敗時）: _______________________
備考: _______________________________________
```

---

## 次のステップ

マイグレーション完了後:

1. バックエンドサーバーを再起動
2. アプリケーションコードをデプロイ
3. レストランのStripe Connect登録テスト
4. 配達員のStripe Connect登録テスト
5. 実際の決済フローをテスト

これでStripe決済が完全に有効化されます。
