# Stripe決済UI 完全実装計画書

作成日: 2025-11-30
参考プロジェクト: timeen, celesmile

---

## 調査結果サマリー

### timeenプロジェクトの実装（完全版）

**特徴**: Stripe Connect Marketplace（雇用者→ワーカーへの報酬支払い）

**実装されている機能**:
1. Stripe Connect Account作成（ワーカー側）
2. オンボーディング画面（UI完備）
3. Payment Intent作成（雇用者が支払い）
4. Transfer実行（ワーカーへの自動振込）
5. Webhook処理（account.updated）
6. Web/モバイル両対応

**ファイル構成**:
- `lib/services/stripe_payment_service.dart` - 決済処理
- `lib/services/stripe_connect_service.dart` - Connect管理
- `lib/screens/stripe_connect_setup_screen.dart` - オンボーディングUI
- `lib/screens/employer_payment_screen.dart` - 支払い画面
- `backend/server.js` - Connect API実装

---

### celesmileプロジェクトの実装（シンプル版）

**特徴**: Direct Charge with Application Fee

**実装されている機能**:
1. Payment Intent作成
2. Payment Sheet表示（モバイル）
3. Web環境対応（代替処理）
4. Application Fee自動計算

**ファイル構成**:
- `lib/services/stripe_service.dart` - 決済処理
- `lib/screens/payment_registration_screen.dart` - 決済UI
- `api/server.js` - Payment Intent API

---

## FoodHub実装計画（3者全て）

### 実装が必要な画面とフロー

#### 1. 顧客側（Customer）: カード決済

**画面**: チェックアウト画面 → Stripe決済画面 → 注文確認画面

**フロー**:
```
1. チェックアウト画面で「カード」選択
2. 「注文を確定する」ボタン押下
3. 注文作成API呼び出し（POST /api/orders）
4. Payment Intent作成API呼び出し（POST /api/orders/:id/create-payment-intent）
5. Stripe Payment Sheet表示
6. カード情報入力
7. 決済完了
8. 注文確認画面に遷移
```

#### 2. レストラン側（Restaurant）: Connect登録

**画面**: ダッシュボード → Stripe設定画面 → オンボーディング

**フロー**:
```
1. レストランダッシュボードに「振込先設定」ボタン追加
2. Stripe設定画面を開く
3. 「Stripe登録を開始」ボタン押下
4. Connect Account作成API呼び出し（POST /api/stripe/connect/restaurant）
5. オンボーディングURLをブラウザで開く
6. Stripeサイトで本人確認・銀行口座登録
7. 完了後、アプリに戻る
8. 「状態を更新」ボタンで確認
```

#### 3. 配達員側（Driver）: Connect登録

**画面**: ダッシュボード → Stripe設定画面 → オンボーディング

**フロー**: レストランと同じ

---

## 詳細実装設計

### Phase 1: 顧客側の決済UI実装

#### ファイル1: StripePaymentService（新規作成）

**パス**: `food_hub/lib/core/services/stripe_payment_service.dart`

**内容**:
```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../../shared/constants/app_constants.dart';

class StripePaymentService {
  static final StripePaymentService _instance = StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  final Dio _dio = Dio();

  /// Stripeを初期化
  Future<void> initialize() async {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    print('[Stripe] Initialized with key: ${AppConstants.stripePublishableKey.substring(0, 20)}...');
  }

  /// Payment Intentを作成
  Future<Map<String, dynamic>> createPaymentIntent(int orderId, String token) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/orders/$orderId/create-payment-intent',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      print('[Stripe] Create payment intent error: $e');
      rethrow;
    }
  }

  /// 決済処理を実行（Payment Sheet使用）
  Future<bool> processPayment({
    required int orderId,
    required String token,
  }) async {
    try {
      print('[Stripe] Processing payment for order: $orderId');

      // 1. Payment Intent作成
      final paymentData = await createPaymentIntent(orderId, token);
      final clientSecret = paymentData['client_secret'] as String;

      print('[Stripe] Client secret received');

      // 2. Payment Sheet初期化
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'FoodHub',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF000000),  // Black theme
            ),
          ),
        ),
      );

      print('[Stripe] Payment sheet initialized');

      // 3. Payment Sheet表示
      await Stripe.instance.presentPaymentSheet();

      print('[Stripe] Payment successful');
      return true;

    } on StripeException catch (e) {
      print('[Stripe] Payment failed: ${e.error.message}');

      // User cancelled
      if (e.error.code == FailureCode.Canceled) {
        print('[Stripe] Payment cancelled by user');
        return false;
      }

      rethrow;
    } catch (e) {
      print('[Stripe] Unexpected error: $e');
      rethrow;
    }
  }
}
```

---

#### ファイル2: チェックアウト画面の修正

**パス**: `food_hub/lib/features/customer/screens/checkout_screen.dart`

**変更箇所**: `_placeOrder()` 関数を修正

```dart
import '../../../core/services/stripe_payment_service.dart';
import '../../../core/storage/storage_service.dart';

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // 既存のフィールド...
  final StripePaymentService _stripeService = StripePaymentService();

  @override
  void initState() {
    super.initState();
    // Stripe初期化
    _stripeService.initialize();
  }

  Future<void> _placeOrder() async {
    // 既存のバリデーション...

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // 1. 注文作成
      final result = await ref.read(createOrderProvider.notifier).placeOrder(
            restaurantId: restaurantId,
            deliveryAddressId: _selectedAddress!.id,
            paymentMethod: _paymentMethod,
            specialInstructions: _specialInstructionsController.text.isNotEmpty
                ? _specialInstructionsController.text
                : null,
          );

      if (!mounted) return;

      await result.when(
        success: (order) async {
          // 2. カード決済の場合、Stripe処理
          if (_paymentMethod == 'card') {
            try {
              // Token取得
              final storageService = ref.read(storageServiceProvider);
              final token = await storageService.getToken();

              if (token == null) {
                throw Exception('認証トークンが見つかりません');
              }

              // Stripe決済実行
              final paymentSuccess = await _stripeService.processPayment(
                orderId: order.id,
                token: token,
              );

              if (!paymentSuccess) {
                // キャンセルされた場合
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('決済がキャンセルされました'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              print('[Checkout] Payment successful for order: ${order.id}');

            } catch (e) {
              // 決済エラー
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('決済に失敗しました: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          // 3. 注文確認画面に遷移（現金 or カード決済成功後）
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/customer/order-confirmation',
              arguments: order,
            );
          }
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('注文に失敗しました: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }
}
```

---

### Phase 2: レストラン側のConnect登録UI実装

#### ファイル1: StripeConnectService（新規作成）

**パス**: `food_hub/lib/core/services/stripe_connect_service.dart`

**内容**:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/constants/app_constants.dart';

class StripeConnectService {
  static final StripeConnectService _instance = StripeConnectService._internal();
  factory StripeConnectService() => _instance;
  StripeConnectService._internal();

  /// Connect Accountを作成
  Future<Map<String, dynamic>> createAccount(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/stripe/connect/restaurant'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      print('[StripeConnect] Create account error: $e');
      rethrow;
    }
  }

  /// アカウント状態を取得
  Future<Map<String, dynamic>> getAccountStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/stripe/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get status');
      }
    } catch (e) {
      print('[StripeConnect] Get status error: $e');
      rethrow;
    }
  }

  /// オンボーディングを開始
  Future<String> startOnboarding(String token) async {
    try {
      // アカウント作成
      final accountData = await createAccount(token);
      return accountData['onboarding_url'] as String;
    } catch (e) {
      print('[StripeConnect] Start onboarding error: $e');
      rethrow;
    }
  }
}
```

---

#### ファイル2: Stripe設定画面（新規作成）

**パス**: `food_hub/lib/features/restaurant/screens/restaurant_stripe_setup_screen.dart`

**内容**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/stripe_connect_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';

class RestaurantStripeSetupScreen extends ConsumerStatefulWidget {
  const RestaurantStripeSetupScreen({super.key});

  @override
  ConsumerState<RestaurantStripeSetupScreen> createState() => _RestaurantStripeSetupScreenState();
}

class _RestaurantStripeSetupScreenState extends ConsumerState<RestaurantStripeSetupScreen> {
  final StripeConnectService _stripeConnectService = StripeConnectService();

  bool _isLoading = true;
  bool _hasAccount = false;
  bool _onboardingComplete = false;
  bool _payoutsEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final token = await storageService.getToken();

      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      final status = await _stripeConnectService.getAccountStatus(token);

      setState(() {
        _hasAccount = status['stripe_account_id'] != null;
        _onboardingComplete = status['stripe_onboarding_completed'] ?? false;
        _payoutsEnabled = status['stripe_payouts_enabled'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final token = await storageService.getToken();

      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      // オンボーディングURL取得
      final url = await _stripeConnectService.startOnboarding(token);

      // ブラウザで開く
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // ダイアログ表示
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stripe登録'),
              content: const Text(
                'Stripeのページで本人確認と銀行口座の登録を完了してください。\n\n'
                '完了後、このページに戻って「状態を更新」ボタンを押してください。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('URLを開けませんでした');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('振込先設定'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.account_balance,
                    size: 80,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Stripe Connect 設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '売上を受け取るためにStripeアカウントの登録が必要です',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // エラーメッセージ
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ステータスカード
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'アカウント状態',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusRow('アカウント作成', _hasAccount),
                          _buildStatusRow('オンボーディング完了', _onboardingComplete),
                          _buildStatusRow('支払い受取可能', _payoutsEnabled),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // アクションボタン
                  if (!_onboardingComplete)
                    ElevatedButton.icon(
                      onPressed: _startOnboarding,
                      icon: const Icon(Icons.launch),
                      label: Text(
                        _hasAccount ? 'オンボーディング続行' : 'Stripe登録を開始',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _loadAccountStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('状態を更新'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 情報セクション
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '登録について',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '・ Stripeは世界中で利用される決済プラットフォームです\n'
                          '・ 本人確認書類（運転免許証など）が必要です\n'
                          '・ 銀行口座情報の登録が必要です\n'
                          '・ 登録完了後、売上の受け取りが可能になります\n'
                          '・ 手数料: 商品代の35%（プラットフォーム手数料）',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isComplete ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### ファイル3: レストランダッシュボードに追加

**パス**: `food_hub/lib/features/restaurant/screens/restaurant_dashboard_screen.dart`

**追加**: 「振込先設定」ボタン

```dart
// ダッシュボードのメニューに追加
ListTile(
  leading: const Icon(Icons.account_balance),
  title: const Text('振込先設定'),
  subtitle: const Text('Stripe Connect'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.pushNamed(context, '/restaurant/stripe-setup');
  },
),
```

**ルート追加** (`main.dart`):
```dart
'/restaurant/stripe-setup': (context) => const RestaurantStripeSetupScreen(),
```

---

### Phase 3: 配達員側のConnect登録UI実装

#### ファイル1: DriverStripeConnectService（新規作成）

**パス**: `food_hub/lib/core/services/driver_stripe_connect_service.dart`

**内容**: レストランと同じ（エンドポイントが `/stripe/connect/driver`）

---

#### ファイル2: 配達員Stripe設定画面（新規作成）

**パス**: `food_hub/lib/features/driver/screens/driver_stripe_setup_screen.dart`

**内容**: レストランと同じUIで、テキストを配達員向けに変更

```dart
'報酬を受け取るためにStripeアカウントの登録が必要です'
'・ 手数料: なし（配送料を全額受け取れます）'
```

---

#### ファイル3: 配達員ダッシュボードに追加

**パス**: `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart`

**追加**: 「振込先設定」ボタン

---

### Phase 4: main.dartの初期化

**パス**: `food_hub/lib/main.dart`

**追加**: Stripe初期化

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/services/stripe_payment_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe初期化
  final stripeService = StripePaymentService();
  await stripeService.initialize();

  // 既存の初期化...

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

## 実装の詳細な流れ

### 顧客の決済フロー（詳細）

```
1. チェックアウト画面で商品確認
   - 小計: ¥2,000
   - 配送料: ¥300
   - サービス料: ¥300（15%）
   - 消費税: ¥260
   - 合計: ¥2,860

2. 支払い方法で「カード」を選択

3. 「注文を確定する」ボタン押下

4. 注文作成API呼び出し
   POST /api/orders
   → Order ID: 123 が返る

5. Payment Intent作成API呼び出し
   POST /api/orders/123/create-payment-intent
   → client_secret: "pi_xxx_secret_yyy" が返る

6. Stripe Payment Sheet初期化
   Stripe.instance.initPaymentSheet(
     clientSecret: "pi_xxx_secret_yyy"
   )

7. Payment Sheet表示
   Stripe.instance.presentPaymentSheet()

8. ユーザーがカード情報入力
   - カード番号: 4242 4242 4242 4242（テスト）
   - 有効期限: 12/25
   - CVC: 123

9. 決済処理
   Stripeサーバーで処理
   → 成功 or 失敗

10. 成功した場合
    - stripe_payment_id がDBに保存される
    - 注文確認画面に遷移

11. 失敗した場合
    - エラーメッセージ表示
    - チェックアウト画面に残る
```

---

### レストランのConnect登録フロー（詳細）

```
1. レストランダッシュボードを開く

2. 「振込先設定」メニューをタップ

3. Stripe設定画面が開く
   - アカウント状態表示:
     ☐ アカウント作成
     ☐ オンボーディング完了
     ☐ 支払い受取可能

4. 「Stripe登録を開始」ボタン押下

5. Connect Account作成API呼び出し
   POST /api/stripe/connect/restaurant
   → account_id: "acct_xxx"
   → onboarding_url: "https://connect.stripe.com/setup/..." が返る

6. ブラウザでStripeサイトが開く

7. Stripeサイトで情報入力:
   ステップ1: ビジネス情報
   - 事業者名
   - 事業内容
   - ビジネスの住所

   ステップ2: 本人確認
   - 運転免許証の写真アップロード
   - または マイナンバーカード

   ステップ3: 銀行口座
   - 銀行名
   - 支店名
   - 口座番号
   - 口座名義

8. 完了
   Stripeから「設定完了」メッセージ

9. アプリに戻る

10. 「状態を更新」ボタン押下

11. アカウント状態確認API呼び出し
    GET /api/stripe/status
    → onboarding_completed: true

12. ステータス表示が更新:
    ☑ アカウント作成
    ☑ オンボーディング完了
    ☑ 支払い受取可能

13. 完了
    売上の受け取りが可能になる
```

---

### 配達員のConnect登録フロー（詳細）

**レストランと同じ** だが、エンドポイントが異なる:
- API: `POST /api/stripe/connect/driver`
- 画面: `DriverStripeSetupScreen`

---

## 必要なファイル一覧

### 新規作成（7ファイル）

#### Flutter側（6ファイル）

1. `food_hub/lib/core/services/stripe_payment_service.dart`
   - 顧客の決済処理

2. `food_hub/lib/core/services/stripe_connect_service.dart`
   - レストランのConnect管理

3. `food_hub/lib/core/services/driver_stripe_connect_service.dart`
   - 配達員のConnect管理

4. `food_hub/lib/features/restaurant/screens/restaurant_stripe_setup_screen.dart`
   - レストランStripe設定画面

5. `food_hub/lib/features/driver/screens/driver_stripe_setup_screen.dart`
   - 配達員Stripe設定画面

6. `food_hub/lib/features/customer/screens/stripe_payment_screen.dart`
   - Stripe決済専用画面（オプション）

#### ドキュメント（1ファイル）

7. `STRIPE_UI_IMPLEMENTATION_PLAN.md`
   - 本ファイル

---

### 変更ファイル（5ファイル）

1. `food_hub/lib/main.dart`
   - Stripe初期化追加
   - ルート追加

2. `food_hub/lib/features/customer/screens/checkout_screen.dart`
   - 決済処理統合

3. `food_hub/lib/features/restaurant/screens/restaurant_dashboard_screen.dart`
   - 振込先設定ボタン追加

4. `food_hub/lib/features/driver/screens/driver_dashboard_screen.dart`
   - 振込先設定ボタン追加

5. `food_hub/pubspec.yaml`
   - 依存関係確認（flutter_stripe, url_launcher）

---

## 依存関係の確認

### 既にインストール済み

```yaml
dependencies:
  flutter_stripe: ^10.2.0  ✅ 既存
  url_launcher: ^6.2.6     ✅ 既存
  dio: ^5.4.3              ✅ 既存
  flutter_riverpod: ^2.5.1 ✅ 既存
```

**追加パッケージ**: なし（全て揃っている）

---

## 実装の優先順位

### 最小限の実装（必須）

**Phase 1**: 顧客の決済UI（2-3時間）
1. StripePaymentService作成
2. checkout_screen.dart修正
3. main.dartでStripe初期化

**動作確認**: カード決済ができるようになる

---

### 推奨実装（完全版）

**Phase 2**: レストランのConnect登録（1-2時間）
1. StripeConnectService作成
2. RestaurantStripeSetupScreen作成
3. ダッシュボードにボタン追加

**Phase 3**: 配達員のConnect登録（1時間）
1. DriverStripeConnectService作成
2. DriverStripeSetupScreen作成
3. ダッシュボードにボタン追加

**合計推定工数**: 4-6時間

---

## テスト手順

### 1. 顧客の決済テスト

```
1. アプリ起動
2. 顧客でログイン
3. レストランで商品をカートに追加
4. チェックアウト
5. 「カード」を選択
6. 「注文を確定する」
7. Payment Sheetが表示されるか確認
8. テストカード入力: 4242 4242 4242 4242
9. 決済成功確認
10. 注文確認画面に遷移確認
```

---

### 2. レストランのConnect登録テスト

```
1. レストランアカウントでログイン
2. ダッシュボードを開く
3. 「振込先設定」をタップ
4. 「Stripe登録を開始」ボタン押下
5. ブラウザでStripeサイトが開くか確認
6. テスト情報を入力
7. 完了後、アプリに戻る
8. 「状態を更新」押下
9. ステータスが全て✅になるか確認
```

---

### 3. 配達完了後の自動送金テスト

```
1. 顧客がカード決済で注文
2. レストランが注文受付
3. 配達員が配達完了にする
4. バックエンドログ確認:
   [PAYOUT] Processing payouts for order 123
   [PAYOUT] Restaurant transfer: tr_xxx
   [PAYOUT] Driver transfer: tr_yyy
   [PAYOUT] Completed for order 123
5. Stripeダッシュボードで Transfer確認
```

---

## 重要な注意事項

### 1. DB変更後のTODOコメント解除

**ファイル**: `foodhub-backend/src/controllers/orderController.js`

**行番号**: 174-182, 607-609, 636-638, 645-647

**作業内容**: `//` を削除してコメント解除

**例**:
```javascript
// 変更前
// service_fee,  // TODO: Add after DB migration

// 変更後
service_fee,
```

---

### 2. テストモードと本番モード

**現在**: テストモード
- Secret Key: `sk_test_...`
- Publishable Key: `pk_test_...`
- テストカードで決済可能

**本番移行時**:
- Secret Key: `sk_live_...` に変更
- Publishable Key: `pk_live_...` に変更
- 実際のカードが使える

---

### 3. Webhookの確認

Stripeダッシュボード → Webhook → エンドポイント確認

**期待されるログ**（バックエンド）:
```
[Stripe Webhook] Received: account.updated
[Stripe Webhook] Restaurant 1 updated
```

---

## まとめ

### 実装に必要なもの

**調査完了**:
- ✅ timeenの完全実装を確認
- ✅ celesmileの実装を確認
- ✅ Stripe Connectの仕組みを理解

**実装対象**:
1. 顧客: カード決済UI
2. レストラン: Connect登録UI
3. 配達員: Connect登録UI

**推定工数**: 4-6時間

**参考コード**: timeenプロジェクトをほぼそのまま流用可能

この計画で実装を開始してよろしいでしょうか？
