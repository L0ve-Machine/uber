# 未実装機能 TODOリスト

最終更新: 2025-11-30

---

## Stripe決済UI実装（優先度: 高）

### 1. 顧客側: カード決済UI

**推定工数**: 2-3時間

**必要なファイル**:
- [ ] `food_hub/lib/core/services/stripe_payment_service.dart`（新規作成）
- [ ] `food_hub/lib/features/customer/screens/checkout_screen.dart`（修正）
- [ ] `food_hub/lib/main.dart`（Stripe初期化追加）

**実装内容**:
1. StripePaymentService作成
2. Payment Intent API呼び出し
3. Payment Sheet表示
4. 決済成功/失敗ハンドリング

**参考**: `STRIPE_UI_IMPLEMENTATION_PLAN.md` の Phase 1

---

### 2. レストラン側: Stripe Connect登録UI

**推定工数**: 1-2時間

**必要なファイル**:
- [ ] `food_hub/lib/core/services/stripe_connect_service.dart`（新規作成）
- [ ] `food_hub/lib/features/restaurant/screens/restaurant_stripe_setup_screen.dart`（新規作成）
- [ ] `food_hub/lib/features/restaurant/screens/restaurant_dashboard_screen.dart`（ボタン追加）
- [ ] `food_hub/lib/main.dart`（ルート追加）

**実装内容**:
1. StripeConnectService作成
2. Stripe設定画面作成
3. オンボーディングフロー実装
4. ダッシュボードに「振込先設定」追加

**参考**: `STRIPE_UI_IMPLEMENTATION_PLAN.md` の Phase 2

---

### 3. 配達員側: Stripe Connect登録UI

**推定工数**: 1時間

**必要なファイル**:
- [ ] `food_hub/lib/core/services/driver_stripe_connect_service.dart`（新規作成）
- [ ] `food_hub/lib/features/driver/screens/driver_stripe_setup_screen.dart`（新規作成）
- [ ] `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart`（ボタン追加）

**実装内容**: レストランと同じ（エンドポイントのみ変更）

**参考**: `STRIPE_UI_IMPLEMENTATION_PLAN.md` の Phase 3

---

### 4. バックエンド: TODOコメント解除

**推定工数**: 5分

**対象ファイル**:
- [ ] `foodhub-backend/src/controllers/orderController.js`

**作業内容**:
- 行174-182のコメント解除（service_fee等のDB保存）
- 行607-609のコメント解除（stripe_restaurant_transfer_id保存）
- 行636-638のコメント解除（stripe_driver_transfer_id保存）
- 行645-647のコメント解除（payout_completed更新）

**前提条件**: DB変更完了後

---

## その他の未実装機能

### 5. Firebase Cloud Messaging（プッシュ通知）

**推定工数**: 3-4時間

**必要な実装**:
- [ ] Firebase初期化
- [ ] FCMトークン取得・保存
- [ ] 通知送信API（バックエンド）
- [ ] 通知ハンドリング（Flutter）

**通知タイミング**:
- 注文受付時
- 配達開始時
- 配達完了5分前
- 配達完了時

**依存関係**: 既にインストール済み（firebase_messaging）

---

### 6. Google Maps統合（配達追跡地図）

**推定工数**: 完了済み ✅

**実装済み**:
- [ ] OpenStreetMap地図表示
- [ ] リアルタイム配達員位置更新
- [ ] プライバシー保護機能

**残作業**: なし（完了）

---

### 7. レビュー写真アップロード

**推定工数**: 2時間

**必要な実装**:
- [ ] 写真選択UI
- [ ] 画像アップロードAPI
- [ ] 画像ストレージ設定
- [ ] レビュー表示に画像追加

**依存関係**: 既にインストール済み（image_picker）

---

### 8. 収益ダッシュボード（管理者向け）

**推定工数**: 3-4時間

**必要な実装**:
- [ ] 管理者画面作成
- [ ] 収益レポートAPI
- [ ] グラフ表示（日次・月次）
- [ ] Export機能（CSV）

**前提条件**: Stripe決済完全実装後

---

### 9. 返金処理

**推定工数**: 2時間

**必要な実装**:
- [ ] 返金API（バックエンド）
- [ ] 返金理由選択UI
- [ ] 部分返金対応
- [ ] 返金履歴表示

**Stripe API**: `stripe.refunds.create()`

---

### 10. クーポン機能の拡張

**推定工数**: 1-2時間

**既存機能**: クーポン適用・削除は実装済み

**未実装**:
- [ ] クーポン作成UI（レストラン側）
- [ ] クーポン一覧表示
- [ ] 有効期限管理
- [ ] 使用回数制限

---

## 実装の推奨順序

### フェーズ1: Stripe決済完成（最優先）

1. 顧客の決済UI（2-3時間）
2. レストランのConnect登録（1-2時間）
3. 配達員のConnect登録（1時間）
4. テストと調整（1時間）

**合計**: 5-7時間

**完了時**: 完全なマーケットプレイス決済が動作

---

### フェーズ2: UX改善

1. プッシュ通知（3-4時間）
2. レビュー写真（2時間）
3. 返金処理（2時間）

**合計**: 7-8時間

---

### フェーズ3: 管理機能

1. 収益ダッシュボード（3-4時間）
2. クーポン管理（1-2時間）

**合計**: 4-6時間

---

## 現在の実装状況

### 完了済み機能

- ✅ ボトムナビゲーションバー
- ✅ 配達追跡（OpenStreetMap + Socket.IO）
- ✅ プライバシー保護機能
- ✅ Stripe決済バックエンド（API完備）
- ✅ 金額計算ロジック（サービス料含む）
- ✅ レストラン・配達員への自動送金ロジック
- ✅ 追跡ボタン（注文詳細・注文履歴）
- ✅ 型パーサー（MySQL DECIMAL対応）

### 未実装機能

- ❌ Stripe決済UI（顧客側）
- ❌ Stripe Connect登録UI（レストラン・配達員）
- ❌ プッシュ通知
- ❌ レビュー写真アップロード
- ❌ 返金処理
- ❌ 収益ダッシュボード

---

## 次のアクション

**推奨**: フェーズ1（Stripe決済完成）を実装

**理由**:
- 決済がないとアプリとして不完全
- バックエンドは既に完成
- UIのみ追加すればすぐ動く
- timeenのコードをほぼコピペ可能

実装を開始しますか？
