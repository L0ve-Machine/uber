# FoodHub プロジェクト状況

**最終更新**: 2025-11-27
**プロジェクト開始日**: 2025-11-22

---

## 全体進捗: 45%

```
Phase 1: ████████████ 100% 完了
Phase 2: ████████████ 100% 完了
Phase 3: ████████░░░░  70% 進行中
Phase 4: ████████████ 100% 完了
Phase 5: ████████████ 100% 完了
Phase 6: ░░░░░░░░░░░░   0% 未着手
```

---

## 完了したフェーズ

### Phase 1: 基盤構築 ✅ 100%

- [x] Flutter プロジェクト構成
- [x] Node.js バックエンド構成
- [x] MySQL データベース設計（11テーブル）
- [x] Riverpod 状態管理セットアップ
- [x] Dio HTTPクライアント設定
- [x] JWT認証システム

### Phase 2: 認証システム ✅ 100%

- [x] ログイン画面（3ユーザータイプ対応）
- [x] 新規登録画面
- [x] 認証状態管理
- [x] トークン保存・自動ログイン

### Phase 4: Restaurant機能 ✅ 100%

- [x] ダッシュボード（注文一覧）
- [x] 注文ステータス変更（受付/調理中/準備完了）
- [x] メニュー管理（一覧、追加、編集）
- [x] 売上統計表示

### Phase 5: Driver機能 ✅ 100%

- [x] ダッシュボード
- [x] オンライン/オフライン切替
- [x] 配達受付・完了
- [x] 配達履歴
- [x] 日別統計

---

## 進行中のフェーズ

### Phase 3: Customer機能 🔄 70%

#### 完了 ✅
- [x] ホーム画面（レストラン一覧）
- [x] レストラン検索・カテゴリフィルター
- [x] レストラン詳細画面・メニュー表示
- [x] カート機能（追加、数量変更、削除）
- [x] 注文履歴画面・注文詳細画面
- [x] **チェックアウト画面** ← 2025-11-27 NEW
- [x] **住所選択画面** ← 2025-11-27 NEW
- [x] **住所追加画面** ← 2025-11-27 NEW
- [x] **注文確認画面** ← 2025-11-27 NEW
- [x] **注文追跡画面（ステータスタイムライン）** ← 2025-11-27 NEW

#### 未完了
- [ ] プロフィール編集
- [ ] お気に入り機能
- [ ] レビュー投稿
- [ ] クーポン適用
- [ ] Stripe決済統合

---

## 今回の実装内容（2025-11-27）

### 5-1: チェックアウト画面の完成 ✅

**新規ファイル:**
```
lib/features/customer/
├── data/
│   ├── services/address_api_service.dart
│   └── repositories/address_repository.dart
├── providers/
│   └── address_provider.dart
└── screens/
    ├── checkout_screen.dart
    ├── address_selection_screen.dart
    ├── add_address_screen.dart
    └── order_confirmation_screen.dart
```

**機能:**
- 配達先住所の選択・追加・デフォルト設定
- 注文内容の確認
- 支払い方法選択（代金引換 / クレジットカード準備中）
- 特別リクエスト入力
- 注文確定・注文番号表示

### 5-3: 注文追跡機能 ✅

**新規ファイル:**
```
lib/features/customer/
├── screens/
│   └── order_tracking_screen.dart
└── widgets/
    └── order_status_timeline.dart
```

**機能:**
- 注文ステータスタイムライン表示
  - 注文受付 → 確認済み → 調理中 → 準備完了 → 配達中 → 配達完了
- 30秒ごとの自動更新（ポーリング）
- 注文キャンセル機能（pending状態のみ）
- 配達先・注文内容・料金表示

---

## 今後の実装予定

### 優先度: 高

| 機能 | 説明 | 状態 |
|-----|------|------|
| Stripe決済統合 | クレジットカード決済 | 未着手 |
| プッシュ通知 | Firebase Cloud Messaging | 未着手 |
| Socket.ioリアルタイム更新 | 注文ステータス即時反映 | 未着手 |

### 優先度: 中

| 機能 | 説明 | 状態 |
|-----|------|------|
| ドライバーGPS追跡 | Google Maps + Geolocator | 未着手 |
| 地図上でのドライバー位置表示 | 顧客アプリ | 未着手 |
| レビュー・評価システム | 店舗・ドライバー両方 | 未着手 |
| プロフィール編集 | 全ユーザータイプ | 未着手 |

### 優先度: 低

| 機能 | 説明 | 状態 |
|-----|------|------|
| クーポン・プロモコード | 割引適用 | 未着手 |
| お気に入り機能 | 店舗・メニュー | 未着手 |
| 注文予約機能 | 指定時間配達 | 未着手 |
| 週次/月次レポート | 店舗・ドライバー向け | 未着手 |

---

## テスト用認証情報

| ユーザータイプ | メール | パスワード |
|--------------|--------|----------|
| 顧客 | customer@test.com | password123 |
| レストラン | restaurant@test.com | password123 |
| 配達員 | driver@test.com | password123 |

---

## 技術的メモ

### 注文ステータス一覧
```
pending     → 注文受付（キャンセル可能）
accepted    → 店舗確認済み
preparing   → 調理中
ready       → 配達準備完了
picked_up   → 配達中
delivered   → 配達完了
cancelled   → キャンセル
```

### APIエンドポイント

**住所関連:**
- `GET /customers/:id/addresses` - 住所一覧
- `POST /customers/:id/addresses` - 住所追加
- `PUT /addresses/:id` - 住所更新
- `DELETE /addresses/:id` - 住所削除
- `PATCH /addresses/:id/default` - デフォルト設定

**注文関連:**
- `POST /orders` - 注文作成
- `GET /orders` - 注文一覧
- `GET /orders/:id` - 注文詳細
- `PATCH /orders/:id/cancel` - キャンセル

---

## ディレクトリ構成

```
uber/
├── food_hub/                 # Flutter アプリ
│   └── lib/
│       ├── core/             # 基盤（theme, routes, network, storage）
│       ├── features/         # 機能別モジュール
│       │   ├── auth/         # 認証
│       │   ├── customer/     # 顧客機能
│       │   ├── restaurant/   # 店舗機能
│       │   └── driver/       # 配達員機能
│       └── shared/           # 共有（models, widgets, constants）
│
├── foodhub-backend/          # Node.js バックエンド
│   └── src/
│       ├── controllers/      # コントローラー
│       ├── models/           # Sequelizeモデル
│       ├── routes/           # ルート定義
│       ├── middleware/       # 認証ミドルウェア
│       └── utils/            # ユーティリティ
│
├── PROJECT_STATUS.md         # このファイル
└── PLAN.md                   # 実装計画詳細
```

---

## クイックスタート

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

---

## マイルストーン

- [x] **M1**: プロジェクト初期化完了 (2025-11-22)
- [x] **M2**: データベース構築完了 (2025-11-22)
- [x] **M3**: 認証システム完了 (2025-11-22)
- [x] **M4**: Customer/Restaurant/Driver UI実装 (2025-11-22)
- [x] **M5**: チェックアウト・注文追跡機能 (2025-11-27) ← NEW
- [ ] **M6**: Stripe決済統合
- [ ] **M7**: リアルタイム機能（Socket.io/Firebase）
- [ ] **M8**: GPS追跡・地図表示
- [ ] **M9**: 本番リリース

---

**次回セッション開始時は、このファイルを確認してください！**
