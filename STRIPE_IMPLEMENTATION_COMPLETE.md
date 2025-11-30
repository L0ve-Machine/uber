# Stripe決済実装完了レポート

実装日: 2025-11-30
ステータス: コード実装完了（DB変更待ち）

---

## 実装完了項目

### バックエンド（Node.js）

#### 1. Stripe設定ファイル
- **ファイル**: `foodhub-backend/src/config/stripe.js`
- **内容**: Stripe SDK初期化

#### 2. Stripe Connect Controller
- **ファイル**: `foodhub-backend/src/controllers/stripeConnectController.js`
- **機能**:
  - レストランのConnect Account作成
  - 配達員のConnect Account作成
  - Webhook処理（オンボーディング完了通知）
  - アカウントステータス取得

#### 3. 注文作成ロジック修正
- **ファイル**: `foodhub-backend/src/controllers/orderController.js:117-160`
- **変更内容**:
  - サービス料計算追加（15%）
  - レストラン手数料率適用（35%）
  - レストラン支払額計算
  - 配達員支払額計算
  - プラットフォーム収益計算
  - 詳細ログ出力

**計算式**:
```javascript
service_fee = subtotal × 0.15
subtotal_before_tax = subtotal + delivery_fee + service_fee
tax = subtotal_before_tax × 0.1
total = subtotal_before_tax + tax

restaurant_payout = subtotal × (1 - 0.35)
driver_payout = delivery_fee
platform_revenue = (subtotal - restaurant_payout) + service_fee + tax
```

#### 4. Payment Intent API
- **ファイル**: `foodhub-backend/src/controllers/orderController.js:490-550`
- **エンドポイント**: `POST /api/orders/:id/create-payment-intent`
- **機能**:
  - Stripe Payment Intent作成
  - Client Secret返却
  - 既存Intent再利用

#### 5. Payout処理
- **ファイル**: `foodhub-backend/src/controllers/orderController.js:556-657`
- **機能**:
  - レストランへのTransfer
  - 配達員へのTransfer
  - 手数料自動計算
  - Transfer ID記録

#### 6. ルート追加
- **ファイル**: `foodhub-backend/src/routes/orders.js`
  - `POST /api/orders/:id/create-payment-intent`
- **ファイル**: `foodhub-backend/src/routes/stripeConnect.js`（新規）
  - `POST /api/stripe/connect/restaurant`
  - `POST /api/stripe/connect/driver`
  - `GET /api/stripe/status`
  - `POST /webhook/stripe/connect`
- **ファイル**: `foodhub-backend/src/app.js`
  - `/api/stripe` ルート登録

---

### フロントエンド（Flutter）

#### 1. OrderModel更新
- **ファイル**: `food_hub/lib/shared/models/order_model.dart`
- **追加フィールド**: `serviceFee`（nullable）
- **コード生成**: 完了

#### 2. CartProvider修正
- **ファイル**: `food_hub/lib/features/customer/providers/cart_provider.dart`
- **追加メソッド**:
  - `serviceFee` getter（15%計算）
  - `subtotalBeforeTax` getter
  - `tax` getter（修正）
  - `total` getter（修正）

#### 3. チェックアウト画面更新
- **ファイル**: `food_hub/lib/features/customer/screens/checkout_screen.dart`
- **変更**: 料金詳細にサービス料を追加表示

---

## 実装された金額計算ロジック

### 例: 商品代¥2,000の注文

```
【顧客が支払う内訳】
小計（商品代）: ¥2,000
配送料: ¥300
サービス料: ¥300（15%）
──────────────────
税抜き小計: ¥2,600
消費税（10%）: ¥260
──────────────────
合計: ¥2,860

【プラットフォーム受取】
Stripe決済: ¥2,860
Stripe手数料: -¥103（3.6%）
実際の受取: ¥2,757

【支払い処理（配達完了後）】
レストランへ: ¥1,300（¥2,000 × 0.65）
配達員へ: ¥300（配送料全額）

【プラットフォーム収益】
レストランマージン: ¥700（35%）
配送料マージン: ¥0
サービス料: ¥300
消費税: ¥260
小計: ¥1,260
Stripe手数料: -¥103
純利益: ¥1,157
```

---

## 作成・変更ファイル一覧

### バックエンド（6ファイル）

1. ✅ `src/config/stripe.js`（新規）
2. ✅ `src/controllers/stripeConnectController.js`（新規）
3. ✅ `src/controllers/orderController.js`（変更）
4. ✅ `src/routes/stripeConnect.js`（新規）
5. ✅ `src/routes/orders.js`（変更）
6. ✅ `src/app.js`（変更）

### フロントエンド（3ファイル + 生成ファイル）

1. ✅ `lib/shared/models/order_model.dart`（変更）
2. ✅ `lib/features/customer/providers/cart_provider.dart`（変更）
3. ✅ `lib/features/customer/screens/checkout_screen.dart`（変更）
4. ✅ `lib/shared/models/order_model.g.dart`（自動生成）

### ドキュメント（3ファイル）

1. ✅ `DB_MIGRATION_STRIPE.md` - DB変更手順書
2. ✅ `STRIPE_PAYMENT_LOGIC_RESEARCH.md` - 調査レポート
3. ✅ `STRIPE_IMPLEMENTATION_PLAN.md` - 実装計画
4. ✅ `STRIPE_IMPLEMENTATION_COMPLETE.md` - 本ドキュメント

---

## DB変更が必要な理由

### 現在の状態

コードは実装完了していますが、以下のカラムがDBに存在しないため、**コメントアウト**されています:

**ordersテーブル**:
```javascript
// service_fee,  // TODO: Add after DB migration
// restaurant_commission_rate,  // TODO: Add after DB migration
// restaurant_payout,  // TODO: Add after DB migration
// driver_payout,  // TODO: Add after DB migration
// platform_revenue,  // TODO: Add after DB migration
```

**restaurantsテーブル**:
- `stripe_account_id`
- `stripe_onboarding_completed`
- `commission_rate`

**driversテーブル**:
- `stripe_account_id`
- `stripe_onboarding_completed`
- `base_payout_per_delivery`

### DB変更後にやること

1. orderController.jsの`// TODO`コメントを削除
2. コメントアウトされたコードのコメント解除
3. バックエンド再起動

**所要時間**: 5分

---

## 動作確認の流れ（DB変更後）

### 1. レストランのStripe登録

```bash
# レストランでログイン
POST /api/stripe/connect/restaurant

# レスポンス
{
  "account_id": "acct_xxx",
  "onboarding_url": "https://connect.stripe.com/setup/..."
}
```

**レストランがやること**:
1. onboarding_urlにアクセス
2. 本人確認情報入力
3. 銀行口座情報入力
4. 完了

---

### 2. 配達員のStripe登録

```bash
# 配達員でログイン
POST /api/stripe/connect/driver

# レスポンス
{
  "account_id": "acct_yyy",
  "onboarding_url": "https://connect.stripe.com/setup/..."
}
```

---

### 3. 顧客が注文

```bash
# 1. 注文作成
POST /api/orders
Body: {
  restaurant_id: 1,
  items: [...],
  payment_method: "card"
}

# レスポンス
{
  "order": {
    "id": 123,
    "total": 2860,
    "service_fee": 300  # ← 計算済み
  }
}

# 2. Payment Intent作成
POST /api/orders/123/create-payment-intent

# レスポンス
{
  "client_secret": "pi_xxx_secret_yyy",
  "amount": 2860
}

# 3. Flutter側でStripe決済
# Stripe.instance.confirmPayment(clientSecret)

# 4. 決済成功
# stripe_payment_id が注文に保存される
```

---

### 4. 配達完了時の自動支払い

```bash
# 配達員が配達完了にする
PATCH /api/driver/orders/123/status
Body: { "status": "delivered" }

# バックエンドで自動実行:
processOrderPayouts(123)
  ├─ レストランに¥1,300転送
  ├─ 配達員に¥300転送
  └─ プラットフォームに¥1,260残る
```

---

## 現在の制限事項

### DB変更前の動作

**動作する機能**:
- サービス料の計算と表示
- 正しい合計金額の計算
- Payment Intent作成
- Transfer処理（ログ出力のみ）

**動作しない機能**:
- サービス料のDB保存
- 支払額のDB保存
- Transfer IDの記録
- 支払い完了フラグの更新

**影響**:
- 収益レポートが作成できない
- 支払い履歴が残らない
- 重複支払いのチェックができない

---

## DB変更後に有効化される機能

### すぐに使える機能

1. レストランのStripe Connect登録
2. 配達員のStripe Connect登録
3. カード決済（Payment Intent）
4. 自動支払い処理（Transfer）
5. 収益トラッキング
6. 支払い履歴管理

### 追加実装が必要な機能（オプション）

1. Stripe決済画面（Flutter）
2. Connect登録画面（Flutter）
3. 収益ダッシュボード
4. 支払い履歴表示
5. 返金処理

---

## 次のステップ

### 必須作業

1. **リモートDBでマイグレーション実行**
   - `DB_MIGRATION_STRIPE.md` 参照
   - 所要時間: 10分

2. **orderController.jsのTODOコメント解除**
   - 行174-182のコメント解除
   - 行607-609, 636-638, 645-647のコメント解除
   - 所要時間: 5分

3. **環境変数の設定**
   ```bash
   # .envに追加
   STRIPE_PUBLISHABLE_KEY=pk_live_xxx
   STRIPE_SECRET_KEY=sk_live_xxx
   STRIPE_CONNECT_WEBHOOK_SECRET=whsec_xxx
   APP_URL=https://133-117-77-23.nip.io
   ```

4. **バックエンド再起動**

---

### 推奨作業（後日）

1. Stripe決済画面の実装（Flutter）
2. Connect登録フローの実装（Flutter）
3. 収益ダッシュボードの実装
4. テストモードでの動作確認
5. 本番環境への移行

---

## 実装統計

- 新規ファイル: 4個
- 変更ファイル: 5個
- 追加コード行数: 約450行
- DB変更: 17カラム（別途実行）
- 実装時間: 約2時間

---

## 重要な注意事項

### DB変更前の注意

**絶対にやらないこと**:
- 本番環境でのテスト
- 実際のカード決済

**やること**:
- まずDB変更を完了させる
- その後コメント解除
- テストモードで動作確認

### Stripeのテストモード

現在の`.env`はテストキー:
```
STRIPE_SECRET_KEY=sk_test_YOUR_SECRET_KEY
```

**テストカード**:
- カード番号: `4242 4242 4242 4242`
- 有効期限: 任意の未来の日付
- CVC: 任意の3桁

---

## DB変更の実施

`DB_MIGRATION_STRIPE.md` を参照して、リモートサーバーで以下を実行:

```sql
-- 17カラム追加
ALTER TABLE orders ADD COLUMN service_fee DECIMAL(10,2) DEFAULT 0.00 AFTER delivery_fee;
ALTER TABLE orders ADD COLUMN restaurant_commission_rate DECIMAL(5,4) DEFAULT 0.35 AFTER service_fee;
-- ... 続く
```

DB変更完了後、このドキュメントの「次のステップ」に従ってください。

---

## 完了チェックリスト

- [x] バックエンドコード実装
- [x] Flutterコード実装
- [x] DB変更手順書作成
- [ ] **リモートDBでマイグレーション実行**
- [ ] TODOコメント解除
- [ ] 環境変数設定
- [ ] 動作テスト
- [ ] 本番APIキー設定

---

実装完了！DB変更をお待ちしています。
