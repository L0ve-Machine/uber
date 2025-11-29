# 🗄️ データベース変更が必要です

## ⚠️ 重要: リモートDBで以下のマイグレーションを実行してください

実装日時: 2025-11-29
対象DB: foodhub (133.117.77.23)

---

## 📋 変更概要

配達追跡機能と複数配達システムを有効化するため、`orders` テーブルに**2つの新規カラム**と**1つのインデックス**を追加します。

---

## 🔧 実行するSQL

### リモートサーバー（133.117.77.23）で実行

```sql
-- データベース選択
USE foodhub;

-- ===== 1. delivery_sequence カラム追加 =====
-- 目的: 配達員が複数注文を持つ場合の配達順序を管理
-- 例: 1=最初に配達, 2=2番目, 3=3番目
ALTER TABLE orders
ADD COLUMN delivery_sequence INT DEFAULT 1
AFTER driver_id
COMMENT '配送順序（1=最初の配達、2=2番目、3=3番目...）';

-- ===== 2. estimated_delivery_time カラム追加 =====
-- 目的: 予想配達時刻を保存（顧客への到着予測表示用）
ALTER TABLE orders
ADD COLUMN estimated_delivery_time TIMESTAMP NULL
AFTER scheduled_at
COMMENT '予想配達時刻（ルート計算またはAI予測値）';

-- ===== 3. パフォーマンス用インデックス追加 =====
-- 目的: 配達員の注文を配達順序で高速取得
CREATE INDEX idx_driver_sequence
ON orders(driver_id, delivery_sequence, status);

-- ===== 4. 既存データの初期化 =====
-- 目的: 既存注文をすべて「1番目の配達」に設定
UPDATE orders
SET delivery_sequence = 1
WHERE delivery_sequence IS NULL;
```

---

## 📊 変更対象テーブル: `orders`

### 変更前の構造（関連カラムのみ）

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,                           -- 既存
    delivery_address_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'preparing', 'ready',
                'picked_up', 'delivering', 'delivered', 'cancelled'),
    -- ... 価格関連カラム省略 ...
    scheduled_at TIMESTAMP NULL,             -- 既存
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    -- 既存インデックス省略 ...
) ENGINE=InnoDB;
```

### 変更後の構造（追加部分を★で表示）

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,
    delivery_sequence INT DEFAULT 1,              -- ★ 追加
    delivery_address_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'preparing', 'ready',
                'picked_up', 'delivering', 'delivered', 'cancelled'),
    -- ... 価格関連カラム省略 ...
    scheduled_at TIMESTAMP NULL,
    estimated_delivery_time TIMESTAMP NULL,       -- ★ 追加
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    -- ... 既存インデックス ...
    INDEX idx_driver_sequence (driver_id, delivery_sequence, status)  -- ★ 追加
) ENGINE=InnoDB;
```

---

## 🎯 追加カラムの詳細仕様

### 1. `delivery_sequence` カラム

**データ型**: `INT`
**NULL許可**: YES
**デフォルト値**: `1`
**位置**: `driver_id` の直後

**用途**:
- 配達員が複数注文を受け持つ場合の配達順序
- 小さい値 = 先に配達
- 顧客への「あと○件配達後」表示に使用
- プライバシー保護判定に使用（1番目の顧客のみ位置情報開示）

**使用例**:

| order_id | driver_id | delivery_sequence | status | 意味 |
|----------|-----------|-------------------|--------|------|
| 101 | 5 | 1 | delivering | 配達員5が**現在配達中** |
| 102 | 5 | 2 | picked_up | 配達員5が次に配達（2番目） |
| 103 | 5 | 3 | picked_up | 配達員5が最後に配達（3番目） |

**APIでの使用**:
```javascript
// 配達員の注文を順序順に取得
const driverOrders = await Order.findAll({
  where: { driver_id: 5, status: ['picked_up', 'delivering'] },
  order: [['delivery_sequence', 'ASC']]  // ← このカラムを使用
});

// 自分が何番目か判定
const myIndex = driverOrders.findIndex(o => o.id === 102);
// → myIndex = 1 (配列の1番目 = 配達順序2番目)

// プライバシー判定
const isCurrentlyDeliveringToMe = (myIndex === 0);  // false
// → 位置情報は非表示
```

---

### 2. `estimated_delivery_time` カラム

**データ型**: `TIMESTAMP`
**NULL許可**: YES
**デフォルト値**: `NULL`
**位置**: `scheduled_at` の直後

**用途**:
- 顧客への到着予測時刻表示
- 配達遅延の検知
- ルート最適化の基準

**計算ロジック例**:
```javascript
// 注文受諾時に計算
const estimatedTime = new Date();
estimatedTime.setMinutes(
  estimatedTime.getMinutes() +
  restaurant.delivery_time_minutes +
  (deliverySequence - 1) * 15  // 前の配達ごとに15分追加
);

await order.update({ estimated_delivery_time: estimatedTime });
```

**使用例**:

| order_id | delivery_sequence | estimated_delivery_time | 計算根拠 |
|----------|-------------------|-------------------------|----------|
| 101 | 1 | 2025-11-29 11:00:00 | 基本30分 |
| 102 | 2 | 2025-11-29 11:15:00 | 基本30分 + 15分 |
| 103 | 3 | 2025-11-29 11:30:00 | 基本30分 + 30分 |

---

### 3. `idx_driver_sequence` インデックス

**インデックス名**: `idx_driver_sequence`
**対象カラム**: `(driver_id, delivery_sequence, status)`
**タイプ**: B-Tree

**用途**:
配達員の現在の配達リストを高速取得

**効果を発揮するクエリ**:
```sql
-- このクエリが高速化される
SELECT * FROM orders
WHERE driver_id = 5
  AND status IN ('picked_up', 'delivering')
ORDER BY delivery_sequence ASC;
```

**パフォーマンス改善**:
- インデックスなし: フルテーブルスキャン（遅い）
- インデックスあり: インデックススキャンのみ（速い）
- 推定速度向上: 10～100倍

---

## 🚀 実行手順

### ステップ1: サーバーにSSH接続

```bash
ssh your_user@133.117.77.23
```

### ステップ2: MySQLにログイン

```bash
mysql -u foodhub_user -p foodhub
# パスワード入力: FoodHub2024Secure!
```

### ステップ3: マイグレーション実行

```sql
-- 以下のSQLを順番にコピペして実行

USE foodhub;

ALTER TABLE orders
ADD COLUMN delivery_sequence INT DEFAULT 1
AFTER driver_id
COMMENT '配送順序（1=最初の配達、2=2番目、3=3番目...）';

ALTER TABLE orders
ADD COLUMN estimated_delivery_time TIMESTAMP NULL
AFTER scheduled_at
COMMENT '予想配達時刻（ルート計算またはAI予測値）';

CREATE INDEX idx_driver_sequence
ON orders(driver_id, delivery_sequence, status);

UPDATE orders
SET delivery_sequence = 1
WHERE delivery_sequence IS NULL;

-- 確認
SHOW COLUMNS FROM orders LIKE '%delivery%';
SHOW COLUMNS FROM orders LIKE 'estimated%';
SHOW INDEXES FROM orders WHERE Key_name = 'idx_driver_sequence';
```

### ステップ4: 実行結果の確認

**期待される出力**:

```
-- SHOW COLUMNS の出力:
+---------------------------+------------+------+-----+---------+-------+
| Field                     | Type       | Null | Key | Default | Extra |
+---------------------------+------------+------+-----+---------+-------+
| delivery_sequence         | int        | YES  | MUL | 1       |       |
| delivery_address_id       | int        | NO   | MUL | NULL    |       |
| delivery_fee              | decimal    | NO   |     | NULL    |       |
| estimated_delivery_time   | timestamp  | YES  |     | NULL    |       |
+---------------------------+------------+------+-----+---------+-------+

-- SHOW INDEXES の出力:
+--------+------------+----------------------+--------------+-------------------+
| Table  | Non_unique | Key_name             | Seq_in_index | Column_name       |
+--------+------------+----------------------+--------------+-------------------+
| orders |          1 | idx_driver_sequence  |            1 | driver_id         |
| orders |          1 | idx_driver_sequence  |            2 | delivery_sequence |
| orders |          1 | idx_driver_sequence  |            3 | status            |
+--------+------------+----------------------+--------------+-------------------+
```

---

## ✅ 実行完了チェックリスト

実行後、以下を確認してください:

- [ ] `delivery_sequence` カラムが追加されている
- [ ] `estimated_delivery_time` カラムが追加されている
- [ ] `idx_driver_sequence` インデックスが作成されている
- [ ] 既存の注文データで `delivery_sequence = 1` になっている
- [ ] エラーが発生していない
- [ ] 既存のアプリケーション機能が正常動作する

---

## 🔄 ロールバック手順（問題発生時）

もし問題が発生した場合、以下で元に戻せます:

```sql
USE foodhub;

-- インデックス削除
DROP INDEX idx_driver_sequence ON orders;

-- カラム削除
ALTER TABLE orders DROP COLUMN estimated_delivery_time;
ALTER TABLE orders DROP COLUMN delivery_sequence;
```

**⚠️ 警告**: カラム削除はデータ消失を伴います。本番環境では事前バックアップ必須。

---

## 📈 影響範囲分析

### 影響を受けるAPI

| API | 影響度 | 内容 |
|-----|-------|------|
| `GET /api/orders/:id/tracking` | 🔴 高 | このカラムを使用（必須） |
| `POST /api/orders` | 🟢 なし | デフォルト値で自動設定 |
| `GET /api/orders` | 🟢 なし | 新カラムは使用しない |
| その他すべてのAPI | 🟢 なし | 影響なし |

### 後方互換性

- ✅ **完全に後方互換**: デフォルト値により既存コードは無変更で動作
- ✅ **ロールバック可能**: カラム削除でいつでも元に戻せる
- ✅ **段階的デプロイ可**: DB変更→アプリデプロイの順序が柔軟

---

## 💾 バックアップ推奨

本番環境では実行前に必ずバックアップを取ってください:

```bash
# ordersテーブルのバックアップ
mysqldump -u foodhub_user -p foodhub orders > orders_backup_20251129.sql

# データベース全体のバックアップ
mysqldump -u foodhub_user -p foodhub > foodhub_backup_20251129.sql
```

---

## 📊 予想実行時間

| データ量 | 予想時間 |
|---------|---------|
| 〜1,000件 | 1秒未満 |
| 〜10,000件 | 1-3秒 |
| 〜100,000件 | 5-10秒 |

**注意**: ALTER TABLE中はテーブルがロックされます。トラフィックが少ない時間帯に実行してください。

---

## 🔍 既存テーブル構造の確認

現在の `orders` テーブルには以下のカラムが存在します:

### 既存のカラム（変更なし）

```sql
id                    INT AUTO_INCREMENT PRIMARY KEY
order_number          VARCHAR(20) NOT NULL UNIQUE
customer_id           INT NOT NULL
restaurant_id         INT NOT NULL
driver_id             INT                           -- ← この直後に delivery_sequence 追加
delivery_address_id   INT NOT NULL
status                ENUM(...)
subtotal              DECIMAL(10,2)
delivery_fee          DECIMAL(10,2)
tax                   DECIMAL(10,2)
discount              DECIMAL(10,2)
total                 DECIMAL(10,2)
payment_method        VARCHAR(50)
stripe_payment_id     VARCHAR(255)
special_instructions  TEXT
scheduled_at          TIMESTAMP NULL                -- ← この直後に estimated_delivery_time 追加
created_at            TIMESTAMP
accepted_at           TIMESTAMP NULL
picked_up_at          TIMESTAMP NULL
delivered_at          TIMESTAMP NULL
cancelled_at          TIMESTAMP NULL
```

### 追加するカラム（★新規）

```sql
delivery_sequence         INT DEFAULT 1            -- ★ 新規
estimated_delivery_time   TIMESTAMP NULL           -- ★ 新規
```

### 追加するインデックス（★新規）

```sql
idx_driver_sequence (driver_id, delivery_sequence, status)  -- ★ 新規
```

---

## 🧪 実行後のテスト

マイグレーション実行後、以下をテストしてください:

### 1. データ整合性チェック

```sql
-- 全注文に delivery_sequence が設定されているか
SELECT COUNT(*) as total,
       COUNT(delivery_sequence) as with_sequence
FROM orders;
-- → total と with_sequence が同じ値であることを確認

-- delivery_sequence の値分布
SELECT delivery_sequence, COUNT(*) as count
FROM orders
GROUP BY delivery_sequence;
-- → ほとんどが 1 になっているはず
```

### 2. インデックス動作確認

```sql
-- インデックスが使用されているか確認
EXPLAIN SELECT * FROM orders
WHERE driver_id = 1
  AND status IN ('picked_up', 'delivering')
ORDER BY delivery_sequence ASC;

-- 出力の「key」列に「idx_driver_sequence」が表示されればOK
```

### 3. アプリケーションテスト

1. バックエンドを再起動（必須ではないが推奨）
2. Flutter アプリで注文追跡画面を開く
3. エラーが発生しないことを確認
4. 配達順序が正しく表示されることを確認

---

## 📞 実行時のサポート

### 実行中にエラーが発生した場合

**エラー: "Duplicate column name 'delivery_sequence'"**
→ 既に実行済みです。`SHOW COLUMNS FROM orders;` で確認してください。

**エラー: "Access denied"**
→ パスワードが間違っています。`.env`ファイルを確認してください。

**エラー: "Table 'orders' is locked"**
→ 別の処理がテーブルをロック中です。少し待ってから再実行してください。

---

## 📅 実施記録

マイグレーション実施後、以下を記録してください:

```
実施日時: YYYY-MM-DD HH:MM:SS
実施者: ________
実行サーバー: 133.117.77.23
実行結果: □ 成功 / □ 失敗
影響件数: ______ 件
実行時間: ______ 秒
エラー内容（失敗時）: ___________________
備考: ___________________________________
```

---

## 🎉 実行完了後

マイグレーション完了後:

1. ✅ バックエンドを再起動
2. ✅ Flutter アプリをリビルド
3. ✅ 配達追跡機能をテスト
4. ✅ Socket.IO接続を確認
5. ✅ 地図表示を確認

これで配達追跡機能が完全に有効化されます！
