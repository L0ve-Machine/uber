# クライアント側作業リスト - Stripe設定必須化

作成日: 2025-11-30
対象: Flutterアプリ（このリポジトリ）

---

## 前提条件

このファイルに記載されている作業は**すべてFlutter側（このリポジトリ）で実施**します。
サーバー側の作業は `SERVER_SIDE_TASKS.md` を参照してください。

**重要**: サーバー側作業が完了していることを確認してから、このクライアント側作業を開始してください。

---

## 作業概要

| Phase | 作業内容 | ファイル数 | 推定時間 |
|-------|---------|----------|---------|
| Phase 1 | モデル作成 | 4ファイル | 2時間 |
| Phase 2 | Provider拡張 | 6ファイル | 3時間 |
| Phase 3 | UI改善 | 2ファイル | 2時間 |
| Phase 4 | Repository/Service追加 | 4ファイル | 2時間 |
| **合計** | | **16ファイル** | **9時間** |

---

## Phase 1: モデル作成（4ファイル）

### 1-1. RestaurantModel作成

**ファイル**: `food_hub/lib/shared/models/restaurant_model.dart`

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

**実装後**:
```bash
# コード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 1-2. DriverModel作成

**ファイル**: `food_hub/lib/shared/models/driver_model.dart`

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

**実装後**:
```bash
# コード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Phase 2: Provider拡張（6ファイル）

### 2-1. RestaurantApiService拡張

**ファイル**: `food_hub/lib/features/restaurant/data/services/restaurant_api_service.dart`

**追加するメソッド**:
```dart
import 'package:dio/dio.dart';
import '../../../../shared/models/restaurant_model.dart';

class RestaurantApiService {
  final Dio _dio;

  RestaurantApiService(this._dio);

  // 既存メソッド...

  /// レストランプロフィール取得（追加）
  Future<RestaurantModel> getProfile() async {
    final response = await _dio.get('/restaurant/profile');
    return RestaurantModel.fromJson(response.data);
  }
}
```

---

### 2-2. RestaurantRepository拡張

**ファイル**: `food_hub/lib/features/restaurant/data/repositories/restaurant_repository.dart`

**追加するメソッド**:
```dart
import '../../../../shared/models/restaurant_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_error.dart';

class RestaurantRepository {
  final RestaurantApiService _apiService;

  RestaurantRepository({required RestaurantApiService apiService})
      : _apiService = apiService;

  // 既存メソッド...

  /// レストランプロフィール取得（追加）
  Future<ApiResult<RestaurantModel>> getProfile() async {
    try {
      final restaurant = await _apiService.getProfile();
      return ApiResult.success(restaurant);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}
```

---

### 2-3. RestaurantProfileProvider作成

**ファイル**: `food_hub/lib/features/restaurant/providers/restaurant_profile_provider.dart`

**内容**:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/restaurant_model.dart';
import '../data/repositories/restaurant_repository.dart';
import 'restaurant_menu_provider.dart'; // restaurantRepositoryProviderをインポート

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

**実装後**:
```bash
# コード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2-4. DriverApiService拡張

**ファイル**: `food_hub/lib/features/driver/data/services/driver_api_service.dart`

**追加するメソッド**:
```dart
import 'package:dio/dio.dart';
import '../../../../shared/models/driver_model.dart';

class DriverApiService {
  final Dio _dio;

  DriverApiService(this._dio);

  // 既存メソッド...

  /// 配達員プロフィール取得（追加）
  Future<DriverModel> getProfile() async {
    final response = await _dio.get('/driver/profile');
    return DriverModel.fromJson(response.data);
  }
}
```

---

### 2-5. DriverRepository拡張

**ファイル**: `food_hub/lib/features/driver/data/repositories/driver_repository.dart`

**追加するメソッド**:
```dart
import '../../../../shared/models/driver_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/api_error.dart';

class DriverRepository {
  final DriverApiService _apiService;

  DriverRepository({required DriverApiService apiService})
      : _apiService = apiService;

  // 既存メソッド...

  /// 配達員プロフィール取得（追加）
  Future<ApiResult<DriverModel>> getProfile() async {
    try {
      final driver = await _apiService.getProfile();
      return ApiResult.success(driver);
    } catch (e) {
      return ApiResult.failure(ApiError.fromException(e));
    }
  }
}
```

---

### 2-6. DriverProfileProvider作成

**ファイル**: `food_hub/lib/features/driver/providers/driver_profile_provider.dart`

**内容**:
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/models/driver_model.dart';
import '../data/repositories/driver_repository.dart';
import 'driver_provider.dart'; // driverRepositoryProviderをインポート

part 'driver_profile_provider.g.dart';

@riverpod
class DriverProfile extends _$DriverProfile {
  @override
  Future<DriverModel> build() async {
    final repository = ref.read(driverRepositoryProvider);
    final result = await repository.getProfile();

    return result.when(
      success: (driver) => driver,
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

**実装後**:
```bash
# コード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2-7. RestaurantMenuProviderにバリデーション追加

**ファイル**: `food_hub/lib/features/restaurant/providers/restaurant_menu_provider.dart`

**修正箇所**: `AddMenuItem.add()` メソッド

**変更内容**:

冒頭に以下をインポート:
```dart
import 'restaurant_profile_provider.dart';
```

`add()` メソッドを修正:
```dart
Future<bool> add({
  required String name,
  String? description,
  required double price,
  required String category,
  String? imageUrl,
  List<Map<String, dynamic>>? options,
}) async {
  // ★ Stripe設定チェック（追加）
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

  // ★ 既存の処理（変更なし）
  state = const AsyncValue.loading();

  final repository = ref.read(restaurantMenuRepositoryProvider);
  final result = await repository.addMenuItem(
    name: name,
    description: description,
    price: price,
    category: category,
    imageUrl: imageUrl,
    options: options,
  );

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

### 2-8. DriverProviderにバリデーション追加（2箇所）

**ファイル**: `food_hub/lib/features/driver/providers/driver_provider.dart`

**冒頭に追加**:
```dart
import '../../../shared/models/driver_model.dart';
import 'driver_profile_provider.dart';
```

**修正箇所1**: `DriverOnlineStatus.toggleOnline()` メソッド

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

  // ★ オンラインにする場合、Stripe設定チェック（追加）
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

**修正箇所2**: `AvailableOrders.acceptDelivery()` メソッド

```dart
Future<bool> acceptDelivery(int orderId) async {
  // ★ Stripe設定チェック（追加）
  final driverAsync = ref.read(driverProfileProvider);
  final driver = driverAsync.valueOrNull;

  if (driver == null || !driver.isStripeFullySetup) {
    return false;
  }

  // 既存の処理（変更なし）
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

## Phase 3: UI改善（2ファイル）

### 3-1. RestaurantMenuAddScreenにエラーハンドリング追加

**ファイル**: `food_hub/lib/features/restaurant/screens/restaurant_menu_add_screen.dart`

**修正箇所**: `_addMenuItem()` メソッド内のエラーハンドリング部分

**現在のコード** (失敗時の処理):
```dart
if (success) {
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('メニューを追加しました'),
      backgroundColor: Colors.black,
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('メニューの追加に失敗しました'),
      backgroundColor: Colors.red,
    ),
  );
}
```

**変更後**:
```dart
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantStripeSetupScreen(),
                ),
              );
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
```

**インポート追加**:
```dart
import '../screens/restaurant_stripe_setup_screen.dart';
```

---

### 3-2. DriverDashboardScreenにエラーハンドリング追加

**ファイル**: `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart`

**冒頭にインポート追加**:
```dart
import '../providers/driver_profile_provider.dart';
```

**修正箇所**: `_handleToggleOnline()` メソッド

**現在のコード全体を置き換え**:
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
            (driver.stripeSetupIssue ?? 'Stripe設定が完了していません。') +
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

## Phase 4: 最終調整

### 4-1. RestaurantStripeSetupScreenの更新ボタン動作修正

**ファイル**: `food_hub/lib/features/restaurant/screens/restaurant_stripe_setup_screen.dart`

**修正箇所**: `_loadAccountStatus()` メソッドの最後

**追加するコード**:
```dart
// 既存のsetState後に追加
setState(() {
  _hasAccount = status['stripe_account_id'] != null;
  _onboardingComplete = status['stripe_onboarding_completed'] ?? false;
  _payoutsEnabled = status['stripe_payouts_enabled'] ?? false;
  _isLoading = false;
});

// ★ プロフィールProviderも更新（追加）
ref.read(restaurantProfileProvider.notifier).refresh();
```

**インポート追加**:
```dart
import '../providers/restaurant_profile_provider.dart';
```

---

### 4-2. DriverStripeSetupScreenの更新ボタン動作修正

**ファイル**: `food_hub/lib/features/driver/screens/driver_stripe_setup_screen.dart`

**修正箇所**: `_loadAccountStatus()` メソッドの最後

**追加するコード**:
```dart
// 既存のsetState後に追加
setState(() {
  _hasAccount = status['stripe_account_id'] != null;
  _onboardingComplete = status['stripe_onboarding_completed'] ?? false;
  _payoutsEnabled = status['stripe_payouts_enabled'] ?? false;
  _isLoading = false;
});

// ★ プロフィールProviderも更新（追加）
ref.read(driverProfileProvider.notifier).refresh();
```

**インポート追加**:
```dart
import '../providers/driver_profile_provider.dart';
```

---

## 実装後の確認作業

### コード生成
```bash
cd food_hub
flutter pub run build_runner build --delete-conflicting-outputs
```

### ビルド確認
```bash
flutter analyze
flutter build apk --debug  # Androidの場合
```

---

## 作業チェックリスト

実施後、以下を確認してください:

### Phase 1: モデル
- [ ] `RestaurantModel` が作成されている
- [ ] `DriverModel` が作成されている
- [ ] `.g.dart` ファイルが自動生成されている
- [ ] `isStripeFullySetup` getterが動作する
- [ ] `stripeSetupIssue` getterが動作する

### Phase 2: Provider
- [ ] `RestaurantProfileProvider` が作成されている
- [ ] `DriverProfileProvider` が作成されている
- [ ] `RestaurantMenuProvider.add()` にバリデーションが追加されている
- [ ] `DriverOnlineStatus.toggleOnline()` にバリデーションが追加されている
- [ ] `AvailableOrders.acceptDelivery()` にバリデーションが追加されている

### Phase 3: UI
- [ ] `RestaurantMenuAddScreen` のエラーハンドリングが改善されている
- [ ] `DriverDashboardScreen` のエラーハンドリングが改善されている

### Phase 4: 統合
- [ ] `RestaurantStripeSetupScreen` でプロフィールが更新される
- [ ] `DriverStripeSetupScreen` でプロフィールが更新される

### ビルド
- [ ] `flutter analyze` でエラーが出ない
- [ ] アプリがビルドできる

---

## テスト手順（サーバー側作業完了後）

### テスト1: レストラン - メニュー追加（Stripe未設定）

**前提**:
- サーバー側でDB migration完了
- レストランアカウントでログイン
- `stripe_onboarding_completed = false`

**操作**:
1. メニュー管理画面を開く
2. 「メニュー追加」ボタンをタップ
3. 商品情報を入力
4. 「追加」ボタンをタップ

**期待結果**:
- ダイアログ表示
- タイトル: 「Stripe設定が必要です」
- 「設定画面へ」ボタンあり

---

### テスト2: 配達員 - オンライン切替（Stripe未設定）

**前提**:
- サーバー側でDB migration完了
- 配達員アカウントでログイン
- `stripe_onboarding_completed = false`
- 現在オフライン

**操作**:
1. 配達ダッシュボードを開く
2. オンライン/オフラインスイッチをONにする

**期待結果**:
- スイッチはOFFのまま
- ダイアログ表示
- タイトル: 「Stripe設定が必要です」
- 「設定画面へ」ボタンあり

---

### テスト3: Stripe設定完了後

**前提**:
- Stripe設定画面でオンボーディング完了
- `stripe_onboarding_completed = true`
- `stripe_payouts_enabled = true`

**操作（レストラン）**:
1. メニュー追加
2. 商品情報入力
3. 「追加」ボタンをタップ

**期待結果**:
- メニュー追加成功
- メニューリストに表示される

**操作（配達員）**:
1. オンライン/オフラインスイッチをONにする

**期待結果**:
- スイッチがONになる
- 「オンラインになりました」表示

---

## 実施記録

```
実施日時: _______________
実施者: _______________

【Phase 1: モデル作成】
作成ファイル数: 4ファイル
実施結果: □ 成功 / □ 失敗

【Phase 2: Provider拡張】
修正ファイル数: 6ファイル
実施結果: □ 成功 / □ 失敗

【Phase 3: UI改善】
修正ファイル数: 2ファイル
実施結果: □ 成功 / □ 失敗

【Phase 4: 最終調整】
修正ファイル数: 2ファイル
実施結果: □ 成功 / □ 失敗

【ビルド確認】
flutter analyze: □ 成功 / □ 失敗
アプリビルド: □ 成功 / □ 失敗

エラー内容（失敗時）: _______________________
備考: _______________________________________
```

---

## トラブルシューティング

### エラー1: `RestaurantModel` が見つからない
**原因**: コード生成が未実施
**解決策**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### エラー2: `restaurantProfileProvider` が見つからない
**原因**: コード生成が未実施
**解決策**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### エラー3: APIエラー 404
**原因**: サーバー側のAPI未実装
**解決策**: `SERVER_SIDE_TASKS.md` を確認してサーバー側作業を完了させる

---

## 次のステップ

クライアント側作業完了後:

1. サーバー側とクライアント側の統合テスト
2. Stripe設定フローの動作確認
3. 本番環境デプロイ

---

このファイルを参照しながら、Flutter側の実装を進めてください。
