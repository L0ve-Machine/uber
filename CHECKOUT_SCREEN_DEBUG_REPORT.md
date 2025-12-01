# チェックアウト画面 デバッグレポート

作成日: 2025-12-01
状態: **未解決** - 画面が真っ白のまま表示されない

---

## 問題の概要

### 症状
- チェックアウト画面がヘッダー以外真っ白
- 何もタップできない（戻るボタンも無反応）
- カートデータは正常に取得できている

### 発生条件
1. カート画面で商品を追加
2. 「チェックアウトへ進む」ボタンをタップ
3. チェックアウト画面に遷移
4. **ヘッダー以外が真っ白**

---

## 調査結果

### ログ分析

#### 最新のログ（2025-12-01 00:58）
```
[Cart] Navigating to checkout
[Cart] Cart items count before navigation: 1
[Cart] Cart items: [ちらし寿司]

[Stripe] Initialized with key: pk_test_51SPy873YVgE...

[Checkout] ========== build() START ==========
[Checkout] Got cartItems: 1
[Checkout] Got cartNotifier
[Checkout] Cart is not empty, building full UI
[Checkout] _buildAddressSelector() called
[Checkout] _selectedAddress: null

← ここで完全に止まる
```

#### 重要な発見
1. ✅ `build()` メソッドは呼ばれている
2. ✅ カートデータ（1件）は正常に取得
3. ✅ `_buildAddressSelector()` も呼ばれている
4. ❌ その後、次のウィジェット（Order Items）に進んでいない
5. ❌ 画面は真っ白（何も表示されない）

---

## 発見した問題と修正履歴

### 問題1: RestaurantModel上書き（修正済み）
**コミット**: `93ff716`

**問題**:
- 新規作成した `RestaurantModel` が既存モデルを完全に置き換え
- 既存フィールド（`coverImageUrl`, `rating` など）が消失

**修正**:
- 既存 `RestaurantModel` にStripeフィールドを追加する形に変更

---

### 問題2: getToken()メソッド名エラー（修正済み）
**コミット**: `93ff716`

**問題**:
- `StorageService.getToken()` が存在しない

**修正**:
- `getToken()` → `getAuthToken()` に修正（3箇所）

---

### 問題3: カート画面にサービス料未表示（修正済み）
**コミット**: `b90edcc`

**問題**:
- カート画面の料金詳細にサービス料（15%）が表示されていない

**修正**:
- `_buildPriceRow('サービス料（15%）', cartNotifier.serviceFee)` を追加

---

### 問題4: Builder構文エラー（修正済み）
**コミット**: `865c470`

**問題**:
- Builderウィジェットの閉じ括弧不足
- インデント不整合

**修正**:
- Builder閉じ括弧を追加
- インデント修正

---

### 問題5: discount型エラー（修正済み）
**コミット**: `63deaa9`

**問題**:
- `discount` が int型なのに、double型引数に渡していた

**修正**:
- `discount.toDouble()` に変更

---

### 問題6: _loadDefaultAddress()によるフリーズ（修正済み）
**コミット**: `ee0d335`

**問題**:
- `initState()` で `defaultAddressProvider` を呼び出し
- 非同期処理が完了せず、画面がフリーズ

**修正**:
- `_loadDefaultAddress()` を完全に削除

---

### 問題7: TextField余分な閉じ括弧（修正済み）
**コミット**: `30cb301`

**問題**:
- TextField に余分な `),` があり、構文エラー

**修正**:
- 余分な閉じ括弧を削除

---

## 未解決の問題

### 現在の状況

**すべての構文エラーは解消済み**

```bash
flutter analyze lib/features/customer/screens/checkout_screen.dart
# エラーなし（warningとinfoのみ）
```

しかし、**画面が依然として真っ白**

---

### ログから分かること

1. **build()メソッドは正常に実行されている**
   - `[Checkout] ========== build() START ==========` が出力
   - カートデータも正常（1件）
   - `cartItems.isEmpty` チェックを通過

2. **_buildAddressSelector()も正常に呼ばれている**
   - `[Checkout] _buildAddressSelector() called` が出力
   - ダミーウィジェット（`Card` + `Text`）を返している

3. **その後、処理が止まる**
   - 次のセクション（Order Items）のログが一切出ない
   - 画面は真っ白のまま

---

## 仮説と検証

### 仮説1: ウィジェットが透明または画面外に配置 ❌
**検証**: 背景色を赤に変更 → 真っ赤になった（コンテンツは見えない）
**結論**: ウィジェットは存在するが表示されていない

### 仮説2: カートデータが空 ❌
**検証**: ログで確認
**結論**: カートデータは正常（1件）

### 仮説3: AutoDisposeによるデータ消失 ❌
**検証**: ログで確認
**結論**: チェックアウト画面でカートデータは取得できている

### 仮説4: Builder/Columnネストの問題 ❌
**検証**: Builder と _buildSection() を削除、直接配置に変更
**結論**: 変わらず

### 仮説5: _loadDefaultAddress()によるフリーズ ✅ → ❓
**検証**: _loadDefaultAddress() を削除
**結論**: 住所APIは呼ばれなくなったが、画面は依然として真っ白

### 仮説6: 構文エラー ✅ → ❓
**検証**: TextField余分な閉じ括弧削除
**結論**: 構文エラー解消したが、画面は依然として真っ白

---

## 現在のコード状態

### checkout_screen.dart の構造

```dart
@override
Widget build(BuildContext context) {
  print('[Checkout] ========== build() START ==========');

  final cartItems = ref.watch(cartProvider);
  final cartNotifier = ref.watch(cartProvider.notifier);

  if (cartItems.isEmpty) {
    return Scaffold(...); // 空のカート画面
  }

  print('[Checkout] Cart is not empty, building full UI');

  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(...),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('配達先住所'),
          _buildAddressSelector(),  // ← ダミー: Card + Text('テスト: 住所セクション')

          Text('注文内容'),
          _buildOrderItems(cartItems),

          Text('クーポン'),
          _buildCoupon(),

          Text('特別リクエスト'),
          TextField(...),

          Text('お支払い方法'),
          _buildPaymentMethod(),

          Text('料金詳細'),
          _buildPriceSummary(cartNotifier),

          CustomButton('注文を確定する'),
        ],
      ),
    ),
  );
}
```

---

## 残る可能性

### 可能性1: _buildAddressSelector() の return後に例外発生
**詳細**:
- `_buildAddressSelector()` は呼ばれている
- ダミーウィジェット（`Card` + `Text`）を返している
- しかし、return後にColumn の children構築で例外が発生している可能性

**検証方法**:
- `_buildAddressSelector()` の return 直後にログ追加
- または、`_buildAddressSelector()` をさらにシンプルに（`Container(color: Colors.yellow, child: Text('TEST'))`）

---

### 可能性2: Column の children リスト自体に問題
**詳細**:
- children リストの構築中にエラー発生
- Flutterが例外をキャッチして、空のウィジェットを表示

**検証方法**:
- children を1つずつ追加して、どれが原因か特定
- 最初は `_buildAddressSelector()` のみ
- 次に `_buildOrderItems()` を追加
- ...という形で

---

### 可能性3: _buildOrderItems() など他のメソッドで例外発生
**詳細**:
- ログには出ないが、ウィジェット構築中に Silent Exception が発生
- Flutter がエラーウィジェット（真っ白）を表示

**検証方法**:
- 各 `_buildXXX()` メソッドの先頭にログ追加
- または、すべてダミーウィジェットに置き換え

---

## 次のステップ（推奨）

### ステップ1: 最小限のウィジェットでテスト
`children` を1つだけにして、表示されるか確認：

```dart
children: [
  Container(
    height: 200,
    color: Colors.yellow,
    child: Center(child: Text('TEST', style: TextStyle(fontSize: 24, color: Colors.black))),
  ),
],
```

これで表示されれば、Column/SingleChildScrollViewは正常。
表示されなければ、Scaffoldまたはルーティングの問題。

---

### ステップ2: 1つずつウィジェットを追加
表示が確認できたら、1つずつ追加：

```dart
children: [
  Container(color: Colors.yellow, child: Text('TEST')),  // ← これが表示される
  _buildAddressSelector(),  // ← これを追加
],
```

どのウィジェットで止まるか特定。

---

### ステップ3: 問題のウィジェットを特定後、そのメソッド内部を調査
例えば `_buildOrderItems()` で止まる場合：
- `ListView.separated` の問題か
- `shrinkWrap: true` の問題か
- `cartItems` のデータ形式の問題か

---

## 技術的詳細

### 使用しているWidget
- `SingleChildScrollView`
- `Column` (crossAxisAlignment: CrossAxisAlignment.stretch)
- `Card`
- `TextField`
- `ListView.separated` (shrinkWrap: true, physics: NeverScrollableScrollPhysics)
- `RadioListTile`
- `Consumer`

### Provider依存
- `cartProvider` - カートデータ
- `appliedCouponProvider` - クーポン状態
- `createOrderProvider` - 注文作成

### 現在のダミー実装
- `_buildAddressSelector()` → `Card` + `Text('テスト: 住所セクション')`
- 他のメソッドは実装済み

---

## まとめ

### 解決済み
1. ✅ RestaurantModel上書き問題
2. ✅ getToken()メソッド名エラー
3. ✅ カート画面サービス料未表示
4. ✅ Builder構文エラー
5. ✅ discount型エラー
6. ✅ _loadDefaultAddress()フリーズ
7. ✅ TextField構文エラー

### 未解決
- ❌ **チェックアウト画面が真っ白**
- build()は呼ばれている
- カートデータも正常
- しかし何も表示されない

### 次のアクション
1. 最小限のテストウィジェット（Container + Text）で表示確認
2. 1つずつウィジェットを追加して、問題箇所を特定
3. 問題のメソッド内部を詳細調査

---

このファイルは調査の記録です。解決次第、更新します。
