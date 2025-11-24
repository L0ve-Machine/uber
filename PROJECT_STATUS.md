# 🍔 FoodHub プロジェクト状況

**最終更新**: 2025-11-22
**プロジェクト開始日**: 2025-11-22

---

## 📊 全体進捗: 25%

```
Phase 1: ████████████ 100% 完了
Phase 2: ████░░░░░░░░  40% 進行中
Phase 3: ░░░░░░░░░░░░   0% 未着手
Phase 4: ░░░░░░░░░░░░   0% 未着手
Phase 5: ░░░░░░░░░░░░   0% 未着手
Phase 6: ░░░░░░░░░░░░   0% 未着手
```

---

## ✅ 完了したフェーズ

### **Phase 1: 基盤構築** ✅ 100%
**期間**: 2025-11-22
**状態**: 完了

#### Flutter (フロントエンド)
- ✅ プロジェクト作成 (`food_hub`)
- ✅ ディレクトリ構造 (customer/restaurant/driver/shared)
- ✅ 依存パッケージインストール
  - flutter_riverpod (状態管理)
  - dio (HTTP通信)
  - flutter_stripe (決済)
  - google_maps_flutter (地図)
  - socket_io_client (リアルタイム通信)
- ✅ テーマ設定 (白×緑カラー)
- ✅ ルーティング定義
- ✅ 定数・設定ファイル

#### Database (MySQL)
- ✅ MySQL Server 8.0 インストール
- ✅ `foodhub` データベース作成
- ✅ 11テーブル作成
  - customers, customer_addresses
  - restaurants, restaurant_hours
  - menu_items, menu_item_options
  - drivers
  - orders, order_items
  - reviews, favorites
- ✅ テストデータ投入

#### Backend (Node.js)
- ✅ Express.js プロジェクト初期化
- ✅ 依存パッケージインストール
  - express, sequelize, mysql2
  - bcrypt, jsonwebtoken
  - stripe, socket.io
- ✅ Sequelize ORM設定
- ✅ データベース接続確認
- ✅ 基本API構造

---

## 🔄 進行中のフェーズ

### **Phase 2: 認証システム** 🔄 40%
**期間**: 2025-11-22 ~
**状態**: バックエンド完了、フロントエンド未着手

#### Backend API ✅
- ✅ JWT認証ユーティリティ
- ✅ bcryptパスワードハッシュ化
- ✅ Sequelizeモデル (Customer, Restaurant, Driver)
- ✅ 認証コントローラー
- ✅ 認証ルート
  - `POST /api/auth/login`
  - `POST /api/auth/register/customer`
  - `POST /api/auth/register/restaurant`
  - `POST /api/auth/register/driver`
  - `GET /api/auth/me`
- ✅ 認証ミドルウェア
- ✅ テストユーザー準備

#### 次のタスク
- [ ] APIエンドポイントテスト
- [ ] Flutter ログイン画面UI
- [ ] Flutter 認証サービス実装
- [ ] トークン保存・管理 (SharedPreferences)
- [ ] ユーザータイプ別画面遷移

---

## 📅 今後のフェーズ

### **Phase 3: カスタマーアプリ（コア機能）** 📅 0%
**予定期間**: 3週間
**優先度**: 高

#### 3-1: レストラン一覧・検索
- [ ] ホーム画面（レストラン一覧）
- [ ] カテゴリー別フィルター
- [ ] 検索機能
- [ ] レストラン詳細ページ
- [ ] メニュー表示

**API:**
- [ ] `GET /api/restaurants` - レストラン一覧
- [ ] `GET /api/restaurants/:id` - レストラン詳細
- [ ] `GET /api/restaurants/:id/menu` - メニュー取得

#### 3-2: カート・注文機能
- [ ] カート画面
- [ ] 商品追加/削除/数量変更
- [ ] チェックアウト画面
- [ ] Stripe決済統合
- [ ] 注文作成

**API:**
- [ ] `POST /api/orders` - 注文作成
- [ ] `POST /api/payments/create-intent` - Stripe決済

#### 3-3: 注文履歴
- [ ] 注文履歴一覧
- [ ] 注文詳細
- [ ] 再注文機能

**API:**
- [ ] `GET /api/orders` - 注文履歴
- [ ] `GET /api/orders/:id` - 注文詳細

---

### **Phase 4: レストランアプリ** 📅 0%
**予定期間**: 2週間
**優先度**: 高

#### 4-1: ダッシュボード
- [ ] 新規注文一覧（リアルタイム）
- [ ] 注文受付/拒否
- [ ] ステータス更新（調理中→完了）

**API:**
- [ ] `GET /api/restaurant/orders` - 店舗の注文一覧
- [ ] `PATCH /api/orders/:id/accept` - 注文受付
- [ ] `PATCH /api/orders/:id/status` - ステータス更新

#### 4-2: メニュー管理
- [ ] メニュー一覧
- [ ] メニュー追加/編集/削除
- [ ] 在庫管理（売り切れ設定）

**API:**
- [ ] `GET /api/restaurant/menu` - メニュー管理
- [ ] `POST /api/restaurant/menu` - メニュー追加
- [ ] `PUT /api/restaurant/menu/:id` - メニュー編集
- [ ] `DELETE /api/restaurant/menu/:id` - メニュー削除

#### 4-3: 売上管理
- [ ] 日別/週別/月別売上
- [ ] 注文統計

---

### **Phase 5: ドライバーアプリ** 📅 0%
**予定期間**: 2週間
**優先度**: 高

#### 5-1: 配達リクエスト
- [ ] オンライン/オフライン切替
- [ ] 配達リクエスト受信
- [ ] リクエスト受諾/拒否

**API:**
- [ ] `GET /api/driver/available-orders` - 配達可能な注文
- [ ] `POST /api/orders/:id/accept-delivery` - 配達受諾

#### 5-2: ナビゲーション
- [ ] レストランへの経路案内
- [ ] 配達先への経路案内
- [ ] Google Maps 統合
- [ ] ステータス更新（ピックアップ→配達中→完了）

#### 5-3: 収入管理
- [ ] 配達履歴
- [ ] 日別/週別/月別収入

---

### **Phase 6: リアルタイム機能** 📅 0%
**予定期間**: 2週間
**優先度**: 中

#### Socket.io統合
- [ ] 注文状況のリアルタイム更新
- [ ] 配達員位置のリアルタイム追跡
- [ ] プッシュ通知（Firebase）

**API:**
- [ ] WebSocket接続
- [ ] イベント: `order_updated`, `driver_location`, `new_order`

---

### **Phase 7: 追加機能** 📅 0%
**予定期間**: 2週間
**優先度**: 低

#### レビュー・評価
- [ ] レストラン評価
- [ ] 配達員評価
- [ ] コメント・写真投稿

#### その他
- [ ] お気に入り機能
- [ ] クーポン・プロモーション
- [ ] 予約注文
- [ ] 住所管理（複数登録）
- [ ] プロフィール編集

---

### **Phase 8: 最適化・テスト** 📅 0%
**予定期間**: 2週間

- [ ] パフォーマンス最適化
- [ ] エラーハンドリング
- [ ] UI/UXブラッシュアップ
- [ ] E2Eテスト
- [ ] セキュリティ強化（HTTPS化）

---

## 📂 プロジェクト構造

```
C:\Users\genki\Projects\app\uber\
├── food_hub/                    # Flutter アプリ
│   ├── lib/
│   │   ├── core/               # テーマ、ルート
│   │   ├── customer/           # 購入者機能
│   │   ├── restaurant/         # レストラン機能
│   │   ├── driver/             # 配達員機能
│   │   └── shared/             # 共通コード
│   └── pubspec.yaml
│
└── foodhub-backend/             # Node.js API
    ├── src/
    │   ├── config/             # DB設定
    │   ├── models/             # Sequelizeモデル
    │   ├── controllers/        # ビジネスロジック
    │   ├── routes/             # APIルート
    │   ├── middleware/         # 認証等
    │   ├── utils/              # JWT, パスワード等
    │   └── app.js              # メインサーバー
    ├── database/
    │   └── schema.sql          # DBスキーマ
    ├── scripts/
    │   └── updateTestUsers.js  # テストデータ更新
    ├── .env                    # 環境変数
    └── README.md               # API仕様書
```

---

## 🔑 重要情報

### テスト認証情報
| ユーザータイプ | メール | パスワード |
|--------------|--------|----------|
| 顧客 | customer@test.com | password123 |
| レストラン | restaurant@test.com | password123 |
| 配達員 | driver@test.com | password123 |

### データベース
- **Host**: localhost
- **Port**: 3306
- **Database**: foodhub
- **User**: root
- **Password**: Prod/0915

### API
- **URL**: http://localhost:3000
- **環境**: development

---

## 🚀 クイックスタート

### バックエンド起動
```bash
cd C:\Users\genki\Projects\app\uber\foodhub-backend
npm run dev
```

### フロントエンド起動
```bash
cd C:\Users\genki\Projects\app\uber\food_hub
flutter run
```

### APIテスト
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"customer@test.com\",\"password\":\"password123\",\"user_type\":\"customer\"}"
```

---

## 📝 次回のタスク

1. **バックグラウンドプロセスのクリーンアップ**
   - 複数のnodeプロセスが残っている可能性
   - `tasklist | findstr node` で確認
   - 必要に応じて `taskkill /F /IM node.exe`

2. **APIエンドポイントテスト**
   - サーバー再起動
   - ログインAPIテスト
   - レスポンス確認（JWTトークン取得）

3. **Flutter ログイン画面実装**
   - ログイン画面UI
   - APIサービス作成
   - 状態管理（Riverpod）
   - トークン保存

---

## 🐛 既知の問題

### バックグラウンドプロセス
- **問題**: 複数のnodeプロセスが起動中
- **影響**: ポート競合の可能性
- **対処**: 次回セッション開始時に全nodeプロセスをkill

### APIテスト未完了
- **問題**: 認証APIエンドポイントのテストが未完了
- **影響**: ログイン機能の動作確認ができていない
- **対処**: 次回、curlまたはPostmanでテスト

---

## 📊 工数見積もり

| フェーズ | 予定工数 | 実績工数 | 状態 |
|---------|---------|---------|------|
| Phase 1 | 2週間 | 1日 | ✅ 完了 |
| Phase 2 | 2週間 | 0.5日 | 🔄 40% |
| Phase 3 | 3週間 | - | 📅 未着手 |
| Phase 4 | 2週間 | - | 📅 未着手 |
| Phase 5 | 2週間 | - | 📅 未着手 |
| Phase 6 | 2週間 | - | 📅 未着手 |
| Phase 7 | 2週間 | - | 📅 未着手 |
| Phase 8 | 2週間 | - | 📅 未着手 |
| **合計** | **約3.5ヶ月** | **1.5日** | **25%** |

---

## 🎯 マイルストーン

- [x] **M1**: プロジェクト初期化完了 (2025-11-22)
- [x] **M2**: データベース構築完了 (2025-11-22)
- [ ] **M3**: 認証システム完了（APIテスト含む）
- [ ] **M4**: MVP完成（レストラン閲覧＋注文）
- [ ] **M5**: レストランアプリ完成
- [ ] **M6**: ドライバーアプリ完成
- [ ] **M7**: リアルタイム機能完成
- [ ] **M8**: 本番リリース

---

**次回セッション開始時は、このファイルを確認してください！**
