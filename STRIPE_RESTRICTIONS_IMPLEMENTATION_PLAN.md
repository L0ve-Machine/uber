# Stripe設定必須化 実装計画書

作成日: 2025-11-30
目的: レストランと配達員がStripe設定完了まで機能を制限する

---

## 現状調査結果サマリー

### 1. データベース構造（既存）

#### restaurantsテーブル
```sql
-- 既にDB_MIGRATION_STRIPE.mdで定義されている（実行待ち）
stripe_account_id VARCHAR(255) NULL
stripe_onboarding_completed BOOLEAN DEFAULT FALSE
stripe_charges_enabled BOOLEAN DEFAULT FALSE
stripe_payouts_enabled BOOLEAN DEFAULT FALSE
commission_rate DECIMAL(5,4) DEFAULT 0.35
```

#### driversテーブル
```sql
-- 既にDB_MIGRATION_STRIPE.mdで定義されている（実行待ち）
stripe_account_id VARCHAR(255) NULL
stripe_onboarding_completed BOOLEAN DEFAULT FALSE
stripe_payouts_enabled BOOLEAN DEFAULT FALSE
base_payout_per_delivery DECIMAL(10,2) DEFAULT 400.00
```

**結論**: DBカラムは既に設計済み。新規カラム追加は不要。

---

### 2. Flutterアプリ側の現状

#### UserModel（food_hub/lib/shared/models/user_model.dart）
```dart
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String? userType; // 'customer', 'restaurant', 'driver'
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
}
```

**問題点**: Stripe関連フィールドが存在しない

---

#### レストラン側の既存実装

**メニュー追加フロー**:
1. `restaurant_menu_add_screen.dart` - メニュー追加画面
2. `RestaurantMenuProvider.addMenuItem()` - API呼び出し
3. バリデーション: 価格、商品名のみ（**Stripe設定チェックなし**）

**現状**: 誰でもメニューを追加できる（制限なし）

---

#### 配達員側の既存実装

**配達受付フロー**:
1. `AvailableOrdersProvider.acceptDelivery(orderId)` - 配達受付
2. バリデーション: なし（**Stripe設定チェックなし**）

**オンライン/オフライン切り替え**:
1. `DriverOnlineStatusProvider.toggleOnline(bool)` - 状態変更
2. バリデーション: なし（**Stripe設定チェックなし**）

**現状**: 誰でもオンラインになって配達を受けられる（制限なし）

---

#### Stripe設定画面（既に実装済み）

**レストラン**:
- `RestaurantStripeSetupScreen` - 設定画面
- `StripeConnectService.getAccountStatus()` - 状態取得API
  - レスポンス: `stripe_account_id`, `stripe_onboarding_completed`, `stripe_payouts_enabled`

**配達員**:
- `DriverStripeSetupScreen` - 設定画面
- `DriverStripeConnectService.getAccountStatus()` - 状態取得API
  - レスポンス: 同上

**現状**: 画面はあるが、状態をアプリ側で保持・利用していない

---

### 3. バックエンドAPI（想定）

#### GET /api/stripe/status
**リクエスト**:
- Header: `Authorization: Bearer <token>`

**レスポンス**（想定）:
```json
{
  "stripe_account_id": "acct_xxx" or null,
  "stripe_onboarding_completed": true/false,
  "stripe_payouts_enabled": true/false,
  // レストランの場合
  "stripe_charges_enabled": true/false,
  "commission_rate": 0.35,
  // 配達員の場合
  "base_payout_per_delivery": 400.00
}
```

**現状**: APIは実装済みと想定（Stripe設定画面で使用中）

---

## 実装方針

### 原則
1. **DB変更なし** - 既存のDB設計（DB_MIGRATION_STRIPE.md）を使用
2. **新規モデル作成** - RestaurantModel、DriverModelを作成
3. **Provider拡張** - 既存Providerにストライプ状態チェックを追加
4. **UI改善** - 制限時のエラーメッセージとガイド表示

---

## 詳細実装設計

### Phase 1: モデル拡張（新規作成）

#### 1-1. RestaurantModel作成

**パス**: `food_hub/lib/shared/models/restaurant_model.dart`

**内容**:
```dart
import 'package:json_annotation/json_annotation.dart';

part 'restaurant_model.g.dart';

@JsonSerializable()
class RestaurantModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_approved')
  final bool isApproved;
  @JsonKey(name: 'stripe_account_id')
  final String? stripeAccountId;
  @JsonKey(name: 'stripe_onboarding_completed')
  final bool stripeOnboardingCompleted;
  @JsonKey(name: 'stripe_charges_enabled')
  final bool stripeChargesEnabled;
  @JsonKey(name: 'stripe_payouts_enabled')
  final bool stripePayoutsEnabled;
  @JsonKey(name: 'commission_rate')
  final double commissionRate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  RestaurantModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isApproved,
    this.stripeAccountId,
    required this.stripeOnboardingCompleted,
    required this.stripeChargesEnabled,
    required this.stripePayoutsEnabled,
    required this.commissionRate,
    required this.createdAt,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      _$RestaurantModelFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantModelToJson(this);

  /// Stripeが完全に設定されているか
  bool get isStripeFullySetup =>
      stripeOnboardingCompleted && stripePayoutsEnabled;

  /// Stripe設定が不完全な理由を返す
  String? get stripeSetupIssue {
    if (stripeAccountId == null) {
      return 'Stripe登録が完了していません';
    }
    if (!stripeOnboardingCompleted) {
      return 'オンボーディングが未完了です';
    }
    if (!stripePayoutsEnabled) {
      return '支払い受取設定が未完了です';
    }
    return null;
  }
}
```

**理由**:
- レストランのStripe状態を管理
- `isStripeFullySetup` でワンライナーチェック
- `stripeSetupIssue` でエラーメッセージ取得

---

#### 1-2. DriverModel作成

**パス**: `food_hub/lib/shared/models/driver_model.dart`

**内容**:
```dart
import 'package:json_annotation/json_annotation.dart';

part 'driver_model.g.dart';

@JsonSerializable()
class DriverModel {
  final int id;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String phone;
  @JsonKey(name: 'vehicle_type')
  final String vehicleType;
  @JsonKey(name: 'license_plate')
  final String licensePlate;
  @JsonKey(name: 'is_online')
  final bool isOnline;
  @JsonKey(name: 'stripe_account_id')
  final String? stripeAccountId;
  @JsonKey(name: 'stripe_onboarding_completed')
  final bool stripeOnboardingCompleted;
  @JsonKey(name: 'stripe_payouts_enabled')
  final bool stripePayoutsEnabled;
  @JsonKey(name: 'base_payout_per_delivery')
  final double basePayoutPerDelivery;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.vehicleType,
    required this.licensePlate,
    required this.isOnline,
    this.stripeAccountId,
    required this.stripeOnboardingCompleted,
    required this.stripePayoutsEnabled,
    required this.basePayoutPerDelivery,
    required this.createdAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) =>
      _$DriverModelFromJson(json);

  Map<String, dynamic> toJson() => _$DriverModelToJson(this);

  /// Stripeが完全に設定されているか
  bool get isStripeFullySetup =>
      stripeOnboardingCompleted && stripePayoutsEnabled;

  /// Stripe設定が不完全な理由を返す
  String? get stripeSetupIssue {
    if (stripeAccountId == null) {
      return 'Stripe登録が完了していません';
    }
    if (!stripeOnboardingCompleted) {
      return 'オンボーディングが未完了です';
    }
    if (!stripePayoutsEnabled) {
      return '支払い受取設定が未完了です';
    }
    return null;
  }
}
```

---

### Phase 2: Provider拡張

#### 2-1. RestaurantProfileProvider作成

**パス**: `food_hub/lib/features/restaurant/providers/restaurant_profile_provider.dart`

**目的**: レストラン自身の情報（Stripe状態含む）を管理

**内容**:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/restaurant_model.dart';
import '../data/repositories/restaurant_repository.dart';

part 'restaurant_profile_provider.g.dart';

@riverpod
class RestaurantProfile extends _$RestaurantProfile {
  @override
  Future<RestaurantModel> build() async {
    final repository = ref.read(restaurantRepositoryProvider);
    final result = await repository.getProfile();

    return result.when(
      success: (restaurant) => restaurant,
      failure: (error) => throw error,
    );
  }

  /// プロフィールをリフレッシュ（Stripe設定後に呼ぶ）
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}
```

---

#### 2-2. DriverProfileProvider作成

**パス**: `food_hub/lib/features/driver/providers/driver_profile_provider.dart`

**目的**: 配達員自身の情報（Stripe状態含む）を管理

**内容**: RestaurantProfileProviderと同様

---

#### 2-3. RestaurantMenuProviderにバリデーション追加

**パス**: `food_hub/lib/features/restaurant/providers/restaurant_menu_provider.dart`

**修正箇所**: `AddMenuItem.add()` メソッド

**変更前**:
```dart
Future<bool> add({...}) async {
  state = const AsyncValue.loading();

  final repository = ref.read(restaurantMenuRepositoryProvider);
  final result = await repository.addMenuItem(...);

  return result.when(
    success: (menuItem) {
      state = AsyncValue.data(menuItem);
      ref.invalidate(restaurantMenuProvider());
      return true;
    },
    failure: (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return false;
    },
  );
}
```

**変更後**:
```dart
Future<bool> add({...}) async {
  // ★ Stripe設定チェック
  final restaurantAsync = ref.read(restaurantProfileProvider);
  final restaurant = restaurantAsync.valueOrNull;

  if (restaurant == null) {
    state = AsyncValue.error(
      Exception('レストラン情報の取得に失敗しました'),
      StackTrace.current,
    );
    return false;
  }

  if (!restaurant.isStripeFullySetup) {
    state = AsyncValue.error(
      Exception(restaurant.stripeSetupIssue ?? 'Stripe設定が必要です'),
      StackTrace.current,
    );
    return false;
  }

  // 既存の処理
  state = const AsyncValue.loading();
  final repository = ref.read(restaurantMenuRepositoryProvider);
  final result = await repository.addMenuItem(...);

  return result.when(
    success: (menuItem) {
      state = AsyncValue.data(menuItem);
      ref.invalidate(restaurantMenuProvider());
      return true;
    },
    failure: (error) {
      state = AsyncValue.error(error, StackTrace.current);
      return false;
    },
  );
}
```

---

#### 2-4. DriverOnlineStatusProviderにバリデーション追加

**パス**: `food_hub/lib/features/driver/providers/driver_provider.dart`

**修正箇所**: `DriverOnlineStatus.toggleOnline()` メソッド

**変更後**:
```dart
Future<bool> toggleOnline(bool isOnline) async {
  // オフラインにする場合はチェック不要
  if (!isOnline) {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.toggleOnlineStatus(isOnline);

    return result.when(
      success: (newStatus) {
        state = newStatus;
        return true;
      },
      failure: (error) => false,
    );
  }

  // ★ オンラインにする場合、Stripe設定チェック
  final driverAsync = ref.read(driverProfileProvider);
  final driver = driverAsync.valueOrNull;

  if (driver == null) {
    return false;
  }

  if (!driver.isStripeFullySetup) {
    // エラーを通知（UI側でハンドル）
    return false;
  }

  // 既存の処理
  final repository = ref.read(driverRepositoryProvider);
  final result = await repository.toggleOnlineStatus(isOnline);

  return result.when(
    success: (newStatus) {
      state = newStatus;
      if (newStatus) {
        ref.invalidate(availableOrdersProvider);
      }
      return true;
    },
    failure: (error) => false,
  );
}
```

---

#### 2-5. AvailableOrdersProviderにバリデーション追加

**パス**: `food_hub/lib/features/driver/providers/driver_provider.dart`

**修正箇所**: `AvailableOrders.acceptDelivery()` メソッド

**変更後**:
```dart
Future<bool> acceptDelivery(int orderId) async {
  // ★ Stripe設定チェック
  final driverAsync = ref.read(driverProfileProvider);
  final driver = driverAsync.valueOrNull;

  if (driver == null || !driver.isStripeFullySetup) {
    return false;
  }

  // 既存の処理
  final repository = ref.read(driverRepositoryProvider);
  final result = await repository.acceptDelivery(orderId);

  return result.when(
    success: (order) {
      state.whenData((orders) {
        final updatedOrders = orders.where((o) => o.id != orderId).toList();
        state = AsyncValue.data(updatedOrders);
      });
      ref.invalidate(activeDeliveriesProvider);
      return true;
    },
    failure: (error) => false,
  );
}
```

---

### Phase 3: UI改善

#### 3-1. RestaurantMenuAddScreenにエラーハンドリング追加

**パス**: `food_hub/lib/features/restaurant/screens/restaurant_menu_add_screen.dart`

**修正箇所**: `_addMenuItem()` メソッド

**変更後**:
```dart
Future<void> _addMenuItem() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
  });

  final success = await ref.read(addMenuItemProvider.notifier).add(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
      );

  if (!mounted) return;

  setState(() {
    _isLoading = false;
  });

  if (success) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メニューを追加しました'),
        backgroundColor: Colors.black,
      ),
    );
  } else {
    // ★ エラーハンドリング拡張
    final error = ref.read(addMenuItemProvider).error;
    final isStripeError = error.toString().contains('Stripe');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isStripeError ? 'Stripe設定が必要です' : 'エラー'),
        content: Text(
          isStripeError
              ? error.toString().replaceAll('Exception: ', '') +
                  '\n\n設定画面からStripe登録を完了してください。'
              : 'メニューの追加に失敗しました',
        ),
        actions: [
          if (isStripeError)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/restaurant/stripe-setup');
              },
              child: const Text('設定画面へ'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isStripeError ? 'キャンセル' : '閉じる'),
          ),
        ],
      ),
    );
  }
}
```

---

#### 3-2. DriverDashboardScreenにエラーハンドリング追加

**パス**: `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart`

**修正箇所**: `_handleToggleOnline()` メソッド

**変更後**:
```dart
Future<void> _handleToggleOnline(bool isOnline) async {
  // オフラインにする場合は通常処理
  if (!isOnline) {
    final success = await ref
        .read(driverOnlineStatusProvider.notifier)
        .toggleOnline(isOnline);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'オフラインになりました' : '状態の変更に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
    return;
  }

  // ★ オンラインにする場合、Stripe設定チェック
  final driverAsync = ref.read(driverProfileProvider);
  final driver = driverAsync.valueOrNull;

  if (driver == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配達員情報の取得に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  if (!driver.isStripeFullySetup) {
    // Stripe設定が未完了の場合、ダイアログ表示
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Stripe設定が必要です'),
          content: Text(
            driver.stripeSetupIssue ?? 'Stripe設定が完了していません。' +
                '\n\n報酬を受け取るためには、Stripe登録を完了してください。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverStripeSetupScreen(),
                  ),
                );
              },
              child: const Text('設定画面へ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
          ],
        ),
      );
    }
    return;
  }

  // Stripe設定完了済み、通常処理
  final success = await ref
      .read(driverOnlineStatusProvider.notifier)
      .toggleOnline(isOnline);

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'オンラインになりました' : '状態の変更に失敗しました'),
        backgroundColor: success ? AppColors.success : Colors.red,
      ),
    );
  }
}
```

---

#### 3-3. DriverOrderCardに配達受付エラーハンドリング追加

**パス**: `food_hub/lib/features/driver/widgets/driver_order_card.dart`

**修正**: `onAccept` コールバック呼び出し箇所

配達受付失敗時にダイアログ表示（DriverDashboardScreenの `_handleAcceptDelivery()` で実装）

---

### Phase 4: バックエンドAPI対応（必要に応じて）

#### 4-1. GET /api/restaurant/profile

**目的**: レストラン自身の情報（Stripe状態含む）を取得

**リクエスト**:
```
GET /api/restaurant/profile
Authorization: Bearer <restaurant_token>
```

**レスポンス**:
```json
{
  "id": 1,
  "name": "レストランA",
  "description": "...",
  "image_url": "...",
  "is_approved": true,
  "stripe_account_id": "acct_xxx",
  "stripe_onboarding_completed": true,
  "stripe_charges_enabled": true,
  "stripe_payouts_enabled": true,
  "commission_rate": 0.35,
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

#### 4-2. GET /api/driver/profile

**目的**: 配達員自身の情報（Stripe状態含む）を取得

**リクエスト**:
```
GET /api/driver/profile
Authorization: Bearer <driver_token>
```

**レスポンス**:
```json
{
  "id": 1,
  "full_name": "配達員A",
  "phone": "090-1234-5678",
  "vehicle_type": "bike",
  "license_plate": "XX-1234",
  "is_online": false,
  "stripe_account_id": "acct_yyy",
  "stripe_onboarding_completed": true,
  "stripe_payouts_enabled": true,
  "base_payout_per_delivery": 400.00,
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

### Phase 5: RepositoryとAPIサービス追加

#### 5-1. RestaurantRepository.getProfile()

**パス**: `food_hub/lib/features/restaurant/data/repositories/restaurant_repository.dart`

**追加メソッド**:
```dart
Future<ApiResult<RestaurantModel>> getProfile() async {
  try {
    final response = await _apiService.getProfile();
    return ApiResult.success(response);
  } catch (e) {
    return ApiResult.failure(ApiError.fromException(e));
  }
}
```

---

#### 5-2. RestaurantApiService.getProfile()

**パス**: `food_hub/lib/features/restaurant/data/services/restaurant_api_service.dart`

**追加メソッド**:
```dart
Future<RestaurantModel> getProfile() async {
  final response = await _dio.get('/restaurant/profile');
  return RestaurantModel.fromJson(response.data);
}
```

---

#### 5-3. DriverRepository.getProfile()

同様に実装

---

## 実装ファイル一覧

### 新規作成（10ファイル）

1. `food_hub/lib/shared/models/restaurant_model.dart` - レストランモデル
2. `food_hub/lib/shared/models/restaurant_model.g.dart` - 自動生成
3. `food_hub/lib/shared/models/driver_model.dart` - 配達員モデル
4. `food_hub/lib/shared/models/driver_model.g.dart` - 自動生成
5. `food_hub/lib/features/restaurant/providers/restaurant_profile_provider.dart` - レストランプロフィールProvider
6. `food_hub/lib/features/restaurant/providers/restaurant_profile_provider.g.dart` - 自動生成
7. `food_hub/lib/features/driver/providers/driver_profile_provider.dart` - 配達員プロフィールProvider
8. `food_hub/lib/features/driver/providers/driver_profile_provider.g.dart` - 自動生成
9. `STRIPE_RESTRICTIONS_IMPLEMENTATION_PLAN.md` - 本ファイル
10. (オプション) `TEST_STRIPE_RESTRICTIONS.md` - テスト手順書

---

### 修正ファイル（7ファイル）

1. `food_hub/lib/features/restaurant/providers/restaurant_menu_provider.dart` - Stripe設定チェック追加
2. `food_hub/lib/features/restaurant/screens/restaurant_menu_add_screen.dart` - エラーハンドリング改善
3. `food_hub/lib/features/driver/providers/driver_provider.dart` - Stripe設定チェック追加（2箇所）
4. `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart` - エラーハンドリング改善
5. `food_hub/lib/features/restaurant/data/repositories/restaurant_repository.dart` - getProfile()追加
6. `food_hub/lib/features/restaurant/data/services/restaurant_api_service.dart` - getProfile()追加
7. `food_hub/lib/features/driver/data/repositories/driver_repository.dart` - getProfile()追加
8. `food_hub/lib/features/driver/data/services/driver_api_service.dart` - getProfile()追加

---

## バックエンド対応必要性

### 必須実装

1. **GET /api/restaurant/profile** - レストラン情報取得API
   - 既存のテーブルから `restaurants` の全カラムを返す
   - Stripe関連フィールドも含む

2. **GET /api/driver/profile** - 配達員情報取得API
   - 既存のテーブルから `drivers` の全カラムを返す
   - Stripe関連フィールドも含む

3. **メニュー追加APIの修正** (オプション)
   - `POST /api/menu-items` でStripe設定チェックを追加
   - クライアント側でチェックするため、サーバー側は任意

4. **配達受付APIの修正** (オプション)
   - `POST /api/orders/:id/accept-delivery` でStripe設定チェックを追加
   - クライアント側でチェックするため、サーバー側は任意

---

## テスト計画

### テストケース1: レストラン - Stripe未設定

**前提条件**:
- レストランアカウントでログイン
- `stripe_onboarding_completed = false`

**操作**:
1. メニュー追加画面を開く
2. 商品情報を入力
3. 「追加」ボタンを押す

**期待結果**:
- エラーダイアログ表示
- メッセージ: 「Stripe登録が完了していません」
- 「設定画面へ」ボタンあり

---

### テストケース2: レストラン - Stripe設定完了

**前提条件**:
- レストランアカウントでログイン
- `stripe_onboarding_completed = true`
- `stripe_payouts_enabled = true`

**操作**:
1. メニュー追加画面を開く
2. 商品情報を入力
3. 「追加」ボタンを押す

**期待結果**:
- メニュー追加成功
- メニューリストに表示される

---

### テストケース3: 配達員 - オンライン切替（Stripe未設定）

**前提条件**:
- 配達員アカウントでログイン
- `stripe_onboarding_completed = false`
- 現在オフライン

**操作**:
1. オンライン/オフラインスイッチをONにする

**期待結果**:
- スイッチはOFFのまま
- ダイアログ表示
- メッセージ: 「Stripe登録が完了していません」
- 「設定画面へ」ボタンあり

---

### テストケース4: 配達員 - オンライン切替（Stripe設定完了）

**前提条件**:
- 配達員アカウントでログイン
- `stripe_onboarding_completed = true`
- `stripe_payouts_enabled = true`
- 現在オフライン

**操作**:
1. オンライン/オフラインスイッチをONにする

**期待結果**:
- スイッチがONになる
- 「オンラインになりました」メッセージ表示
- 利用可能な配達リストが表示される

---

### テストケース5: 配達員 - 配達受付（Stripe未設定）

**前提条件**:
- 配達員アカウントでログイン
- `stripe_onboarding_completed = false`
- オンライン状態（手動でスイッチON）

**操作**:
1. 利用可能な配達リストを開く
2. 配達を受け付ける

**期待結果**:
- 受付失敗
- エラーメッセージ表示

---

## 実装優先順位

### 高優先度（必須）

1. **RestaurantModel作成** - Stripe状態管理の基盤
2. **DriverModel作成** - Stripe状態管理の基盤
3. **RestaurantProfileProvider** - レストラン情報取得
4. **DriverProfileProvider** - 配達員情報取得
5. **バックエンドAPI実装** - GET /api/restaurant/profile、GET /api/driver/profile

### 中優先度（推奨）

6. **RestaurantMenuProviderバリデーション** - メニュー追加制限
7. **DriverOnlineStatusProviderバリデーション** - オンライン切替制限
8. **AvailableOrdersProviderバリデーション** - 配達受付制限

### 低優先度（任意）

9. **UIエラーハンドリング改善** - ユーザー体験向上
10. **バックエンドバリデーション** - 二重チェック

---

## 推定工数

- **Phase 1**: モデル作成 - 2時間
- **Phase 2**: Provider拡張 - 3時間
- **Phase 3**: UI改善 - 2時間
- **Phase 4**: バックエンドAPI - 3時間
- **Phase 5**: Repository/Service追加 - 2時間
- **テスト**: 2時間

**合計**: 14時間

---

## まとめ

### 実装の鍵

1. **DB変更不要** - 既存のDB設計を活用
2. **モデル中心設計** - RestaurantModel、DriverModelで状態管理
3. **Provider層でバリデーション** - ビジネスロジックを集約
4. **UI層で親切なエラー表示** - ユーザー導線を明確化

### 影響範囲

- **レストラン**: メニュー追加時にStripe設定必須
- **配達員**: オンライン切替・配達受付時にStripe設定必須
- **顧客**: 影響なし

### リスクと対策

**リスク**: 既存レストラン・配達員が使えなくなる
**対策**: Stripe設定画面への誘導を明確化、エラーメッセージを分かりやすく

---

この計画で実装を開始してよろしいでしょうか？
