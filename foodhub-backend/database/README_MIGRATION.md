# データベースマイグレーション手順書

## 概要
配達追跡機能と複数配達システムを実装するためのデータベース変更手順書です。

---

## 📋 変更内容サマリー

### 変更対象テーブル: `orders`

| 項目 | 内容 |
|------|------|
| 新規カラム数 | 2カラム |
| 新規インデックス | 1つ |
| データ更新 | 既存レコードのデフォルト値設定 |
| 影響範囲 | 注文配達機能 |

---

## 🔧 詳細な変更内容

### 1. 新規カラム追加

#### 1-1. `delivery_sequence` カラム

**目的**: 1人の配達員が複数注文を配達する際の順序を管理

**仕様**:
```sql
ALTER TABLE orders
ADD COLUMN delivery_sequence INT DEFAULT 1
AFTER driver_id
COMMENT '配送順序（1=最初の配達、2=2番目、3=3番目...）';
```

**詳細**:
- **カラム名**: `delivery_sequence`
- **データ型**: `INT`
- **NOT NULL**: いいえ（NULL許可）
- **デフォルト値**: `1`
- **配置位置**: `driver_id` カラムの直後
- **用途**:
  - 配達員が複数注文を受け持つ場合の配達順序
  - 1 = 最初に配達する注文
  - 2 = 2番目に配達する注文
  - 3 = 3番目に配達する注文
  - 数値が小さいほど優先度が高い

**使用例**:
```sql
-- 配達員ID=5が3つの注文を持つ場合
INSERT INTO orders (driver_id, delivery_sequence, ...) VALUES
(5, 1, ...),  -- 1番目に配達
(5, 2, ...),  -- 2番目に配達
(5, 3, ...);  -- 3番目に配達
```

---

#### 1-2. `estimated_delivery_time` カラム

**目的**: 予想配達時刻を保存（ルート最適化や到着時刻予測に使用）

**仕様**:
```sql
ALTER TABLE orders
ADD COLUMN estimated_delivery_time TIMESTAMP NULL
AFTER scheduled_at
COMMENT '予想配達時刻（計算またはAIによる予測値）';
```

**詳細**:
- **カラム名**: `estimated_delivery_time`
- **データ型**: `TIMESTAMP`
- **NOT NULL**: いいえ（NULL許可）
- **デフォルト値**: `NULL`
- **配置位置**: `scheduled_at` カラムの直後
- **用途**:
  - 顧客への予想到着時刻表示
  - 配達ルート最適化の基準
  - 配達遅延の検知

**使用例**:
```sql
-- 注文作成時に30分後を予想配達時刻として設定
UPDATE orders
SET estimated_delivery_time = DATE_ADD(NOW(), INTERVAL 30 MINUTE)
WHERE id = 123;
```

---

### 2. インデックス追加

#### 2-1. `idx_driver_sequence` 複合インデックス

**目的**: 配達員ごとの注文を配達順序で効率的に取得

**仕様**:
```sql
CREATE INDEX idx_driver_sequence
ON orders(driver_id, delivery_sequence, status);
```

**詳細**:
- **インデックス名**: `idx_driver_sequence`
- **対象カラム**:
  1. `driver_id` (配達員ID)
  2. `delivery_sequence` (配達順序)
  3. `status` (注文ステータス)
- **インデックスタイプ**: B-Tree (デフォルト)
- **用途**:
  - 配達員の現在の配達順序を高速取得
  - アクティブな配達のみをフィルタリング

**効果を発揮するクエリ例**:
```sql
-- 配達員ID=5の配達中の注文を順序順に取得
SELECT * FROM orders
WHERE driver_id = 5
  AND status IN ('picked_up', 'delivering')
ORDER BY delivery_sequence ASC;

-- このクエリがインデックスを使用して高速化される
```

---

### 3. 既存データの更新

#### 3-1. デフォルト値の設定

**目的**: 既存の注文レコードにデフォルト値を設定

**仕様**:
```sql
UPDATE orders
SET delivery_sequence = 1
WHERE delivery_sequence IS NULL;
```

**詳細**:
- すべての既存注文の `delivery_sequence` を `1` に設定
- これにより、過去の注文も「1番目の配達」として扱われる
- 既存のアプリケーションロジックとの互換性を保つ

---

## 📊 変更前後のテーブル構造比較

### 変更前の `orders` テーブル（関連カラムのみ）

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,                    -- 配達員ID
    delivery_address_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'preparing', 'ready',
                'picked_up', 'delivering', 'delivered', 'cancelled'),
    -- ... 価格関連カラム省略 ...
    scheduled_at TIMESTAMP NULL,       -- 予約配達時刻
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    -- ... インデックス省略 ...
) ENGINE=InnoDB;
```

### 変更後の `orders` テーブル（関連カラムのみ）

```sql
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,
    delivery_sequence INT DEFAULT 1,           -- ★ 新規追加
    delivery_address_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'preparing', 'ready',
                'picked_up', 'delivering', 'delivered', 'cancelled'),
    -- ... 価格関連カラム省略 ...
    scheduled_at TIMESTAMP NULL,
    estimated_delivery_time TIMESTAMP NULL,    -- ★ 新規追加
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    -- ... その他インデックス省略 ...
    INDEX idx_driver_sequence (driver_id, delivery_sequence, status)  -- ★ 新規追加
) ENGINE=InnoDB;
```

---

## 🚀 実行手順

### 方法1: SQLファイルを使用（推奨）

#### Step 1: サーバーにSSH接続
```bash
ssh user@133.117.77.23
```

#### Step 2: マイグレーションファイルをアップロード
```bash
# ローカル（あなたのPC）で実行
scp foodhub-backend/database/migrations/001_add_delivery_sequence.sql user@133.117.77.23:/tmp/
```

#### Step 3: MySQLにログイン
```bash
# サーバーで実行
mysql -u foodhub_user -p foodhub
# パスワード入力: FoodHub2024Secure!
```

#### Step 4: マイグレーション実行
```bash
# MySQL内で実行
source /tmp/001_add_delivery_sequence.sql;
```

または、ワンライナーで：
```bash
mysql -u foodhub_user -p foodhub < /tmp/001_add_delivery_sequence.sql
```

---

### 方法2: 手動SQL実行（小規模なら推奨）

#### Step 1: MySQLにログイン
```bash
mysql -u foodhub_user -p foodhub
```

#### Step 2: 以下のSQLを順番に実行

```sql
-- 1. delivery_sequenceカラム追加
ALTER TABLE orders
ADD COLUMN delivery_sequence INT DEFAULT 1
AFTER driver_id
COMMENT '配送順序（1=最初の配達、2=2番目、3=3番目...）';

-- 2. estimated_delivery_timeカラム追加
ALTER TABLE orders
ADD COLUMN estimated_delivery_time TIMESTAMP NULL
AFTER scheduled_at
COMMENT '予想配達時刻（計算またはAIによる予測値）';

-- 3. インデックス追加
CREATE INDEX idx_driver_sequence
ON orders(driver_id, delivery_sequence, status);

-- 4. 既存データ更新
UPDATE orders
SET delivery_sequence = 1
WHERE delivery_sequence IS NULL;

-- 5. 確認
SHOW COLUMNS FROM orders LIKE '%delivery%';
SHOW INDEXES FROM orders WHERE Key_name = 'idx_driver_sequence';
```

---

### 方法3: Node.jsスクリプトで実行（自動化）

リモートDB接続情報を `.env` に設定してある場合:

```bash
# foodhub-backend/database/ ディレクトリで実行
node run-migration.js
```

**注意**: `.env` の `DB_HOST` がリモートサーバーのIPになっていることを確認してください。

---

## ✅ 実行後の確認

### 1. カラムの確認
```sql
DESCRIBE orders;

-- 出力例:
-- delivery_sequence      | int          | YES  |     | 1       |
-- estimated_delivery_time | timestamp    | YES  |     | NULL    |
```

### 2. インデックスの確認
```sql
SHOW INDEXES FROM orders;

-- 出力に以下が含まれることを確認:
-- idx_driver_sequence | driver_id
-- idx_driver_sequence | delivery_sequence
-- idx_driver_sequence | status
```

### 3. データの確認
```sql
SELECT id, driver_id, delivery_sequence, status
FROM orders
LIMIT 10;

-- すべての既存レコードで delivery_sequence = 1 になっていることを確認
```

---

## 🔄 ロールバック手順（問題が発生した場合）

万が一問題が発生した場合、以下のSQLで変更を元に戻せます:

```sql
-- インデックス削除
DROP INDEX idx_driver_sequence ON orders;

-- カラム削除
ALTER TABLE orders DROP COLUMN estimated_delivery_time;
ALTER TABLE orders DROP COLUMN delivery_sequence;
```

**警告**: カラムを削除すると、そのカラムのデータは完全に失われます。本番環境では必ずバックアップを取ってから実行してください。

---

## 📝 影響範囲

### アプリケーションコードへの影響

**影響あり**:
- ✅ 注文追跡API (`GET /api/orders/:id/tracking`)
  - `delivery_sequence` を使用して配達順序を計算
  - このカラムがない場合は `created_at` で代替可能（機能は限定的）

**影響なし（後方互換性あり）**:
- ✅ 注文作成API (`POST /api/orders`)
  - デフォルト値 `1` が自動設定される
- ✅ 注文一覧API (`GET /api/orders`)
  - 新しいカラムを使用しない
- ✅ その他すべてのAPI
  - 既存機能に影響なし

---

## 💡 追加実装の推奨事項（オプション）

将来的に以下のテーブル・カラムの追加も検討できます:

### Phase 2: 配送バッチテーブル（完全な複数配達システム）

```sql
CREATE TABLE delivery_batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    total_orders INT DEFAULT 0,
    total_distance_km DECIMAL(5,2),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    INDEX idx_driver_status (driver_id, status)
) ENGINE=InnoDB;

-- ordersテーブルにbatch_id追加
ALTER TABLE orders
ADD COLUMN batch_id INT NULL
AFTER driver_id,
ADD FOREIGN KEY (batch_id) REFERENCES delivery_batches(id);
```

**メリット**:
- より精密な配達管理
- 配達効率の分析が可能
- バッチ単位での報酬計算

---

## 📞 サポート

実行中に問題が発生した場合:

1. エラーメッセージを確認
2. ロールバックSQLを実行
3. データベースのバックアップを確認
4. 開発チームに連絡

---

## 📅 実施日時記録

マイグレーション実施後、以下を記録してください:

```
実施日時: YYYY-MM-DD HH:MM:SS
実施者: ________
実行環境: 本番 / ステージング / 開発
実行結果: 成功 / 失敗
備考: ___________________________
```
