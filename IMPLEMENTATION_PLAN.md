
# 実装計画書: 顧客機能（残り4機能）

**作成日**: 2025-11-27
**対象機能**: プロフィール編集、お気に入り、レビュー投稿、クーポン適用

---

## 現状分析サマリー

### 既存のデータベース構造

| テーブル | 状態 | 備考 |
|---------|------|------|
| `customers` | ✅ 存在 | 基本プロフィール項目あり |
| `favorites` | ✅ 存在 | customer_id, restaurant_id |
| `reviews` | ✅ 存在 | order_id, ratings, comment |
| `coupons` | ❌ 未作成 | 新規作成必要 |

### 既存のバックエンド実装

| 機能 | Model | Controller | Routes |
|------|-------|------------|--------|
| Favorites | ✅ Favorite.js | ✅ favoriteController.js | ⚠️ 部分的 (GET欠落) |
| Reviews | ❌ なし | ❌ なし | ❌ なし |
| Profile | ✅ Customer.js | ❌ 更新APIなし | ❌ なし |
| Coupons | ❌ なし | ❌ なし | ❌ なし |

### 既存のFlutter実装

| 機能 | Model | Provider | Screen |
|------|-------|----------|--------|
| Favorites | ❌ なし | ❌ なし | ❌ なし |
| Reviews | ❌ なし | ❌ なし | ❌ なし |
| Profile | ✅ UserModel (基本) | ✅ AuthProvider | ❌ 編集画面なし |
| Coupons | ❌ なし | ❌ なし | ❌ なし |

---

## 機能1: プロフィール編集

### 1.1 概要
顧客が自分のプロフィール情報（名前、電話番号、プロフィール画像）を編集できる機能

### 1.2 データベース変更
**変更不要** - `customers`テーブルに必要なカラムは既に存在:
- `full_name` VARCHAR(100)
- `phone` VARCHAR(20)
- `profile_image_url` TEXT

### 1.3 バックエンド実装

#### 新規ファイル
```
foodhub-backend/src/
├── controllers/customerController.js  ← 新規作成
└── routes/customers.js                ← 新規作成
```

#### APIエンドポイント
| Method | Endpoint | 説明 |
|--------|----------|------|
| GET | `/api/customers/:id` | プロフィール取得 |
| PUT | `/api/customers/:id` | プロフィール更新 |
| PATCH | `/api/customers/:id/password` | パスワード変更 |

#### customerController.js 実装内容
```javascript
// getProfile - プロフィール取得
// updateProfile - full_name, phone, profile_image_url の更新
// changePassword - 現在のパスワード確認 + 新パスワードハッシュ化
```

#### app.js への追加
```javascript
app.use('/api/customers', require('./routes/customers'));
```

### 1.4 Flutter実装

#### 新規ファイル
```
food_hub/lib/features/customer/
├── data/
│   ├── services/profile_api_service.dart      ← 新規
│   └── repositories/profile_repository.dart   ← 新規
├── providers/
│   └── profile_provider.dart                  ← 新規
└── screens/
    ├── profile_screen.dart                    ← 新規
    └── edit_profile_screen.dart               ← 新規
```

#### 新規モデル（不要）
既存の`UserModel`を使用

#### profile_api_service.dart
```dart
@RestApi()
abstract class ProfileApiService {
  @GET('/customers/{id}')
  Future<UserModel> getProfile(@Path() int id);

  @PUT('/customers/{id}')
  Future<UserModel> updateProfile(@Path() int id, @Body() Map<String, dynamic> data);

  @PATCH('/customers/{id}/password')
  Future<void> changePassword(@Path() int id, @Body() Map<String, dynamic> data);
}
```

#### profile_provider.dart
```dart
@riverpod
class Profile extends _$Profile {
  // updateProfile() - API呼び出し + AuthProviderのユーザー更新
  // changePassword() - パスワード変更
}
```

#### 画面構成
- **profile_screen.dart**: プロフィール表示 + 編集ボタン + 注文履歴リンク
- **edit_profile_screen.dart**: フォーム（名前、電話番号、画像アップロード）

#### ルート追加 (app_routes.dart)
```dart
static const String editProfile = '/customer/profile/edit';
```

---

## 機能2: お気に入り

### 2.1 概要
顧客がレストランをお気に入り登録し、一覧表示・解除できる機能

### 2.2 データベース変更
**変更不要** - `favorites`テーブルは既に存在:
```sql
CREATE TABLE favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_favorite (customer_id, restaurant_id)
);
```

### 2.3 バックエンド実装

#### 既存ファイルの修正
```
foodhub-backend/src/routes/favorites.js  ← GET追加
```

#### 現在のエンドポイント
| Method | Endpoint | 状態 |
|--------|----------|------|
| POST | `/api/favorites` | ✅ 実装済み |
| DELETE | `/api/favorites/:id` | ✅ 実装済み |
| GET | `/api/customers/:id/favorites` | ⚠️ Controller有、Route無 |

#### favorites.js への追加
```javascript
// GET /api/customers/:customerId/favorites を追加
router.get(
  '/customers/:customerId',
  authMiddleware,
  isCustomer,
  favoriteController.getFavorites
);
```

**または** addresses.js と同じパターンで `/api/customers/:id/favorites` をaddresses routeに統合

### 2.4 Flutter実装

#### 新規ファイル
```
food_hub/lib/features/customer/
├── data/
│   ├── services/favorite_api_service.dart      ← 新規
│   └── repositories/favorite_repository.dart   ← 新規
├── providers/
│   └── favorite_provider.dart                  ← 新規
└── screens/
    └── favorites_screen.dart                   ← 新規
```

#### 新規モデル
```
food_hub/lib/shared/models/favorite_model.dart  ← 新規
```

#### favorite_model.dart
```dart
@JsonSerializable()
class FavoriteModel {
  final int id;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;
  final RestaurantModel? restaurant;  // include時
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
}
```

#### favorite_api_service.dart
```dart
@RestApi()
abstract class FavoriteApiService {
  @GET('/customers/{customerId}/favorites')
  Future<FavoritesResponse> getFavorites(@Path() int customerId);

  @POST('/favorites')
  Future<FavoriteModel> addFavorite(@Body() Map<String, dynamic> data);

  @DELETE('/favorites/{id}')
  Future<void> removeFavorite(@Path() int id);
}
```

#### favorite_provider.dart
```dart
@riverpod
class Favorites extends _$Favorites {
  // AsyncValue<List<FavoriteModel>> 状態
  // addFavorite(restaurantId)
  // removeFavorite(favoriteId)
  // isFavorited(restaurantId) - 同期チェック
}

@riverpod
Future<bool> isFavorited(int restaurantId);  // 個別チェック用
```

#### 画面構成
- **favorites_screen.dart**: お気に入りレストラン一覧（RestaurantCardを再利用）

#### UI変更: restaurant_detail_screen.dart
- ハートアイコンボタン追加（AppBarのactions）
- タップでお気に入り追加/解除

#### ルート追加
```dart
static const String favorites = '/customer/favorites';
```

---

## 機能3: レビュー投稿

### 3.1 概要
配達完了後、顧客がレストランとドライバーに対してレビュー（星評価+コメント）を投稿できる機能

### 3.2 データベース変更
**変更不要** - `reviews`テーブルは既に存在:
```sql
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,        -- 1注文1レビュー
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,                        -- 配達員（nullable）
    restaurant_rating TINYINT CHECK (1-5),
    driver_rating TINYINT CHECK (1-5),
    comment TEXT,
    images JSON,                          -- ["url1", "url2"]
    created_at TIMESTAMP
);
```

### 3.3 バックエンド実装

#### 新規ファイル
```
foodhub-backend/src/
├── models/Review.js           ← 新規作成
├── controllers/reviewController.js  ← 新規作成
└── routes/reviews.js          ← 新規作成
```

#### APIエンドポイント
| Method | Endpoint | 説明 |
|--------|----------|------|
| POST | `/api/reviews` | レビュー投稿 |
| GET | `/api/restaurants/:id/reviews` | レストランのレビュー一覧 |
| GET | `/api/orders/:id/review` | 注文のレビュー取得 |
| PUT | `/api/reviews/:id` | レビュー編集（24時間以内） |
| DELETE | `/api/reviews/:id` | レビュー削除 |

#### Review.js モデル
```javascript
const Review = sequelize.define('Review', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  order_id: { type: DataTypes.INTEGER, allowNull: false, unique: true },
  customer_id: { type: DataTypes.INTEGER, allowNull: false },
  restaurant_id: { type: DataTypes.INTEGER, allowNull: false },
  driver_id: { type: DataTypes.INTEGER, allowNull: true },
  restaurant_rating: { type: DataTypes.TINYINT, validate: { min: 1, max: 5 } },
  driver_rating: { type: DataTypes.TINYINT, validate: { min: 1, max: 5 } },
  comment: { type: DataTypes.TEXT },
  images: { type: DataTypes.JSON, defaultValue: [] },
}, { tableName: 'reviews', timestamps: true, updatedAt: false });
```

#### reviewController.js 実装内容
```javascript
// createReview - 注文ステータス確認(delivered)、重複チェック
// getRestaurantReviews - ページネーション付き
// getOrderReview - 注文に紐づくレビュー取得
// updateReview - 24時間以内のみ許可
// deleteReview - 本人のみ削除可能
// updateRestaurantRating - レビュー投稿時にrestaurantsテーブルのrating更新
```

#### models/index.js への追加
```javascript
const Review = require('./Review');

// Review associations
Review.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });
Review.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Review.belongsTo(Restaurant, { foreignKey: 'restaurant_id', as: 'restaurant' });
Review.belongsTo(Driver, { foreignKey: 'driver_id', as: 'driver' });
```

#### app.js への追加
```javascript
app.use('/api/reviews', require('./routes/reviews'));
```

### 3.4 Flutter実装

#### 新規ファイル
```
food_hub/lib/features/customer/
├── data/
│   ├── services/review_api_service.dart      ← 新規
│   └── repositories/review_repository.dart   ← 新規
├── providers/
│   └── review_provider.dart                  ← 新規
├── screens/
│   └── write_review_screen.dart              ← 新規
└── widgets/
    ├── star_rating_widget.dart               ← 新規
    └── review_card.dart                      ← 新規
```

#### 新規モデル
```
food_hub/lib/shared/models/review_model.dart  ← 新規
```

#### review_model.dart
```dart
@JsonSerializable()
class ReviewModel {
  final int id;
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'customer_id')
  final int customerId;
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'restaurant_rating')
  final int restaurantRating;
  @JsonKey(name: 'driver_rating')
  final int? driverRating;
  final String? comment;
  final List<String>? images;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Nested objects (when included)
  final CustomerBasicModel? customer;
}

@JsonSerializable()
class CustomerBasicModel {
  final int id;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
}

@JsonSerializable()
class CreateReviewRequest {
  @JsonKey(name: 'order_id')
  final int orderId;
  @JsonKey(name: 'restaurant_rating')
  final int restaurantRating;
  @JsonKey(name: 'driver_rating')
  final int? driverRating;
  final String? comment;
  final List<String>? images;
}
```

#### review_api_service.dart
```dart
@RestApi()
abstract class ReviewApiService {
  @POST('/reviews')
  Future<ReviewModel> createReview(@Body() CreateReviewRequest request);

  @GET('/restaurants/{id}/reviews')
  Future<ReviewsResponse> getRestaurantReviews(@Path() int id, @Query('page') int page);

  @GET('/orders/{id}/review')
  Future<ReviewModel?> getOrderReview(@Path() int id);

  @PUT('/reviews/{id}')
  Future<ReviewModel> updateReview(@Path() int id, @Body() Map<String, dynamic> data);

  @DELETE('/reviews/{id}')
  Future<void> deleteReview(@Path() int id);
}
```

#### review_provider.dart
```dart
@riverpod
class Reviews extends _$Reviews {
  // getRestaurantReviews(restaurantId, page)
  // createReview(request)
  // updateReview(id, data)
  // deleteReview(id)
}

@riverpod
Future<ReviewModel?> orderReview(int orderId);  // 注文のレビュー取得
```

#### 画面構成
- **write_review_screen.dart**:
  - レストラン評価（星1-5）
  - ドライバー評価（星1-5、ドライバー有りの場合）
  - コメント入力
  - 画像添付（オプション）
  - 送信ボタン

#### ウィジェット
- **star_rating_widget.dart**: タップ可能な星評価（1-5）
- **review_card.dart**: レビュー表示カード（顧客名、星、コメント、日付）

#### UI変更
1. **order_detail_screen.dart**: 配達完了時に「レビューを書く」ボタン表示
2. **restaurant_detail_screen.dart**: レビュー一覧セクション追加

#### ルート追加
```dart
static const String writeReview = '/customer/review/write/:orderId';
```

---

## 機能4: クーポン適用

### 4.1 概要
顧客がクーポンコードを入力し、注文に割引を適用できる機能

### 4.2 データベース変更
**新規テーブル作成必要**

#### schema.sql への追加
```sql
-- ============================================
-- COUPONS (クーポン)
-- ============================================
CREATE TABLE coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type ENUM('percentage', 'fixed') NOT NULL,  -- 割合 or 固定金額
    discount_value DECIMAL(10,2) NOT NULL,               -- 10(%) or 500(円)
    min_order_amount DECIMAL(10,2) DEFAULT 0.00,         -- 最低注文金額
    max_discount_amount DECIMAL(10,2),                   -- 最大割引額（%の場合）
    max_uses INT,                                         -- 全体使用上限
    max_uses_per_customer INT DEFAULT 1,                 -- 顧客ごとの使用上限
    current_uses INT DEFAULT 0,                          -- 現在の使用回数
    restaurant_id INT,                                    -- NULL = 全店舗対象
    valid_from TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    INDEX idx_code (code),
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_valid_dates (valid_from, valid_until),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB;

-- ============================================
-- COUPON_USAGES (クーポン使用履歴)
-- ============================================
CREATE TABLE coupon_usages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    coupon_id INT NOT NULL,
    customer_id INT NOT NULL,
    order_id INT NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (coupon_id) REFERENCES coupons(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    INDEX idx_coupon_customer (coupon_id, customer_id)
) ENGINE=InnoDB;
```

#### ordersテーブルへの追加カラム
```sql
ALTER TABLE orders ADD COLUMN coupon_id INT AFTER discount;
ALTER TABLE orders ADD FOREIGN KEY (coupon_id) REFERENCES coupons(id);
```

### 4.3 バックエンド実装

#### 新規ファイル
```
foodhub-backend/src/
├── models/Coupon.js           ← 新規作成
├── models/CouponUsage.js      ← 新規作成
├── controllers/couponController.js  ← 新規作成
└── routes/coupons.js          ← 新規作成
```

#### APIエンドポイント
| Method | Endpoint | 説明 |
|--------|----------|------|
| GET | `/api/coupons/available` | 利用可能クーポン一覧 |
| POST | `/api/coupons/validate` | クーポンコード検証 |
| POST | `/api/coupons/apply` | クーポン適用（注文作成時） |

#### Coupon.js モデル
```javascript
const Coupon = sequelize.define('Coupon', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  code: { type: DataTypes.STRING(50), allowNull: false, unique: true },
  description: { type: DataTypes.STRING(255) },
  discount_type: { type: DataTypes.ENUM('percentage', 'fixed'), allowNull: false },
  discount_value: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  min_order_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
  max_discount_amount: { type: DataTypes.DECIMAL(10, 2) },
  max_uses: { type: DataTypes.INTEGER },
  max_uses_per_customer: { type: DataTypes.INTEGER, defaultValue: 1 },
  current_uses: { type: DataTypes.INTEGER, defaultValue: 0 },
  restaurant_id: { type: DataTypes.INTEGER },
  valid_from: { type: DataTypes.DATE, allowNull: false },
  valid_until: { type: DataTypes.DATE, allowNull: false },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
}, { tableName: 'coupons', timestamps: true, underscored: true });
```

#### couponController.js 実装内容
```javascript
// getAvailableCoupons - 有効期限内 & アクティブ & 使用可能なクーポン
// validateCoupon - コード検証
//   - コード存在チェック
//   - 有効期限チェック
//   - アクティブチェック
//   - 使用上限チェック（全体 & 顧客別）
//   - 最低注文金額チェック
//   - レストラン制限チェック
//   - 割引額計算
// applyCouponToOrder - 注文にクーポン適用
//   - coupon_usages レコード作成
//   - coupons.current_uses インクリメント
//   - orders.discount, orders.coupon_id 更新
```

#### models/index.js への追加
```javascript
const Coupon = require('./Coupon');
const CouponUsage = require('./CouponUsage');

// Coupon associations
Coupon.belongsTo(Restaurant, { foreignKey: 'restaurant_id', as: 'restaurant' });
Coupon.hasMany(CouponUsage, { foreignKey: 'coupon_id', as: 'usages' });
CouponUsage.belongsTo(Coupon, { foreignKey: 'coupon_id', as: 'coupon' });
CouponUsage.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
CouponUsage.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });
```

#### orderController.js の修正
```javascript
// createOrder に coupon_code パラメータ追加
// 注文作成時にクーポン検証 & 適用
```

#### app.js への追加
```javascript
app.use('/api/coupons', require('./routes/coupons'));
```

### 4.4 Flutter実装

#### 新規ファイル
```
food_hub/lib/features/customer/
├── data/
│   ├── services/coupon_api_service.dart      ← 新規
│   └── repositories/coupon_repository.dart   ← 新規
├── providers/
│   └── coupon_provider.dart                  ← 新規
├── screens/
│   └── coupons_screen.dart                   ← 新規
└── widgets/
    └── coupon_card.dart                      ← 新規
```

#### 新規モデル
```
food_hub/lib/shared/models/coupon_model.dart  ← 新規
```

#### coupon_model.dart
```dart
@JsonSerializable()
class CouponModel {
  final int id;
  final String code;
  final String? description;
  @JsonKey(name: 'discount_type')
  final String discountType;  // 'percentage' | 'fixed'
  @JsonKey(name: 'discount_value')
  final double discountValue;
  @JsonKey(name: 'min_order_amount')
  final double minOrderAmount;
  @JsonKey(name: 'max_discount_amount')
  final double? maxDiscountAmount;
  @JsonKey(name: 'restaurant_id')
  final int? restaurantId;
  @JsonKey(name: 'valid_from')
  final DateTime validFrom;
  @JsonKey(name: 'valid_until')
  final DateTime validUntil;
  @JsonKey(name: 'is_active')
  final bool isActive;

  // 計算された割引額（検証後）
  double? calculatedDiscount;
}

@JsonSerializable()
class ValidateCouponRequest {
  final String code;
  @JsonKey(name: 'order_subtotal')
  final double orderSubtotal;
  @JsonKey(name: 'restaurant_id')
  final int restaurantId;
}

@JsonSerializable()
class ValidateCouponResponse {
  final bool valid;
  final String? error;
  final CouponModel? coupon;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
}
```

#### coupon_api_service.dart
```dart
@RestApi()
abstract class CouponApiService {
  @GET('/coupons/available')
  Future<CouponsResponse> getAvailableCoupons();

  @POST('/coupons/validate')
  Future<ValidateCouponResponse> validateCoupon(@Body() ValidateCouponRequest request);
}
```

#### coupon_provider.dart
```dart
@riverpod
class AppliedCoupon extends _$AppliedCoupon {
  // AsyncValue<CouponModel?> 状態
  // applyCoupon(code, subtotal, restaurantId) - 検証 & 適用
  // removeCoupon() - クーポン解除
  // discountAmount getter
}

@riverpod
Future<List<CouponModel>> availableCoupons();  // 利用可能クーポン一覧
```

#### 画面構成
- **coupons_screen.dart**: 利用可能クーポン一覧 + コード入力欄

#### ウィジェット
- **coupon_card.dart**: クーポン表示カード（コード、説明、割引額、有効期限）

#### UI変更: checkout_screen.dart
1. 「クーポンを適用」セクション追加
2. クーポンコード入力フィールド
3. 「適用」ボタン
4. 適用済みクーポン表示（コード、割引額、解除ボタン）
5. 合計金額計算にdiscount反映

#### cart_provider.dart の修正
```dart
// appliedCouponProvider との連携
// discount 計算追加
// total = subtotal + deliveryFee + tax - discount
```

#### ルート追加
```dart
static const String coupons = '/customer/coupons';
```

---

## 実装順序（推奨）

### Phase 1: お気に入り機能（難易度: 低）
**理由**: バックエンドの大部分が実装済み、Flutter側のみ追加

1. バックエンド: favorites.js に GET ルート追加
2. Flutter: FavoriteModel 作成
3. Flutter: FavoriteApiService, Repository 作成
4. Flutter: FavoriteProvider 作成
5. Flutter: favorites_screen.dart 作成
6. Flutter: restaurant_detail_screen.dart にハートアイコン追加
7. build_runner 実行
8. テスト

**見積り**: 約10ファイル

### Phase 2: プロフィール編集（難易度: 低〜中）
**理由**: シンプルなCRUD、認証周りの修正が必要

1. バックエンド: customerController.js 作成
2. バックエンド: customers.js ルート作成
3. バックエンド: app.js に追加
4. Flutter: ProfileApiService, Repository 作成
5. Flutter: ProfileProvider 作成
6. Flutter: profile_screen.dart 作成
7. Flutter: edit_profile_screen.dart 作成
8. Flutter: AuthProvider にユーザー更新メソッド追加
9. build_runner 実行
10. テスト

**見積り**: 約12ファイル

### Phase 3: レビュー投稿（難易度: 中）
**理由**: 新規テーブルモデル、レーティング計算ロジック必要

1. バックエンド: Review.js モデル作成
2. バックエンド: models/index.js に追加
3. バックエンド: reviewController.js 作成
4. バックエンド: reviews.js ルート作成
5. バックエンド: app.js に追加
6. Flutter: ReviewModel 作成
7. Flutter: ReviewApiService, Repository 作成
8. Flutter: ReviewProvider 作成
9. Flutter: star_rating_widget.dart 作成
10. Flutter: review_card.dart 作成
11. Flutter: write_review_screen.dart 作成
12. Flutter: restaurant_detail_screen.dart にレビューセクション追加
13. Flutter: order_detail_screen.dart にレビューボタン追加
14. build_runner 実行
15. テスト

**見積り**: 約15ファイル

### Phase 4: クーポン適用（難易度: 高）
**理由**: 新規テーブル2つ、複雑な検証ロジック、既存コードの修正多数

1. データベース: coupons, coupon_usages テーブル作成
2. データベース: orders テーブルに coupon_id カラム追加
3. バックエンド: Coupon.js, CouponUsage.js モデル作成
4. バックエンド: models/index.js に追加
5. バックエンド: couponController.js 作成
6. バックエンド: coupons.js ルート作成
7. バックエンド: orderController.js 修正（クーポン対応）
8. バックエンド: app.js に追加
9. Flutter: CouponModel 作成
10. Flutter: CouponApiService, Repository 作成
11. Flutter: CouponProvider 作成
12. Flutter: coupon_card.dart 作成
13. Flutter: coupons_screen.dart 作成
14. Flutter: checkout_screen.dart 修正（クーポン入力欄追加）
15. Flutter: cart_provider.dart 修正（割引計算追加）
16. Flutter: OrderModel 修正（couponId追加）
17. build_runner 実行
18. テスト

**見積り**: 約20ファイル

---

## ファイル一覧サマリー

### バックエンド新規ファイル (11ファイル)
```
foodhub-backend/src/
├── models/
│   ├── Review.js
│   ├── Coupon.js
│   └── CouponUsage.js
├── controllers/
│   ├── customerController.js
│   ├── reviewController.js
│   └── couponController.js
└── routes/
    ├── customers.js
    ├── reviews.js
    └── coupons.js
```

### バックエンド修正ファイル (4ファイル)
```
foodhub-backend/src/
├── models/index.js          ← associations追加
├── controllers/orderController.js  ← クーポン対応
├── routes/favorites.js      ← GET追加
└── app.js                   ← 新規ルート追加
```

### Flutter新規ファイル (21ファイル)
```
food_hub/lib/
├── shared/models/
│   ├── favorite_model.dart
│   ├── review_model.dart
│   └── coupon_model.dart
└── features/customer/
    ├── data/services/
    │   ├── profile_api_service.dart
    │   ├── favorite_api_service.dart
    │   ├── review_api_service.dart
    │   └── coupon_api_service.dart
    ├── data/repositories/
    │   ├── profile_repository.dart
    │   ├── favorite_repository.dart
    │   ├── review_repository.dart
    │   └── coupon_repository.dart
    ├── providers/
    │   ├── profile_provider.dart
    │   ├── favorite_provider.dart
    │   ├── review_provider.dart
    │   └── coupon_provider.dart
    ├── screens/
    │   ├── profile_screen.dart
    │   ├── edit_profile_screen.dart
    │   ├── favorites_screen.dart
    │   ├── write_review_screen.dart
    │   └── coupons_screen.dart
    └── widgets/
        ├── star_rating_widget.dart
        ├── review_card.dart
        └── coupon_card.dart
```

### Flutter修正ファイル (6ファイル)
```
food_hub/lib/
├── core/routes/app_routes.dart           ← 新規ルート追加
├── features/auth/providers/auth_provider.dart  ← ユーザー更新追加
├── features/customer/providers/cart_provider.dart  ← 割引計算追加
├── features/customer/screens/restaurant_detail_screen.dart  ← ハート、レビュー
├── features/customer/screens/checkout_screen.dart  ← クーポン入力
└── features/customer/screens/order_detail_screen.dart  ← レビューボタン
```

### データベース変更
```
foodhub-backend/database/
└── schema.sql  ← coupons, coupon_usages テーブル追加、orders修正
```

---

## 合計ファイル数

| カテゴリ | 新規 | 修正 | 合計 |
|---------|------|------|------|
| バックエンド | 11 | 4 | 15 |
| Flutter | 21 | 6 | 27 |
| データベース | 0 | 1 | 1 |
| **合計** | **32** | **11** | **43** |

---

## 参考フォルダからの採用事項

参考フォルダ（Food-Ordering-App-main）には以下の機能のみ実装されていた：
- **プロフィール編集**: UserDetailForm.dart を参考にフォーム構造を採用
  - フォーム項目: Email, Phone, Address, Pincode → 本プロジェクトでは Name, Phone, Image

**お気に入り、レビュー、クーポン**は参考フォルダに実装がないため、本プロジェクト独自の設計となる。

---

## 次のステップ

1. この計画書の確認・承認
2. Phase 1（お気に入り機能）から実装開始
3. 各Phase完了後にPROJECT_STATUS.md更新
