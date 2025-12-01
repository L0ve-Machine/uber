# チェックアウト画面エラー分析レポート

作成日: 2025-12-01 01:22
状態: **原因特定完了**

---

## 問題の概要

### 症状
- チェックアウト画面で一部のコンテンツのみ表示される
- 表示されるもの: 黄色テストコンテナ、配達先住所セクション、注文内容タイトル
- 表示されないもの: 注文アイテムリスト、クーポン、支払い方法、料金詳細、注文ボタン

### 再現手順
1. レストラン詳細画面でメニューアイテムをカートに追加
2. カート画面で「チェックアウトへ進む」をタップ
3. チェックアウト画面に遷移
4. 一部のみ表示され、残りが表示されない

---

## ログ分析

### 最新のログ（2025-12-01 01:21:54）

```
[Cart] Navigating to checkout
[Cart] Cart items count before navigation: 1
[Cart] Cart items: [天ぷら盛り合わせ]

[Stripe] Initialized with key: pk_test_51SPy873YVgE...

[Checkout] ========== build() START ==========
[Checkout] Got cartItems: 1
[Checkout] Got cartNotifier
[Checkout] Cart is not empty, building full UI
[Checkout] _buildAddressSelector() called
[Checkout] _selectedAddress: null
[Checkout] _buildOrderItems() called with 1 items
← ここで完全に停止
```

### 重要な発見

1. ✅ `build()` メソッドは正常に実行
2. ✅ カートデータ（1件）は正常に取得
3. ✅ `_buildAddressSelector()` は正常に呼ばれ、ウィジェットを返す
4. ✅ `_buildOrderItems()` も呼ばれている（printログ確認）
5. ❌ **`_buildOrderItems()` 内部でエラー発生**
6. ❌ 以降のメソッド（`_buildCoupon()`, `_buildPaymentMethod()` など）が一切呼ばれない

---

## 原因の特定

### エラー発生箇所

**ファイル**: `food_hub/lib/features/customer/screens/checkout_screen.dart`
**行番号**: 282-302行（`_buildOrderItems()` メソッド）

```dart
Widget _buildOrderItems(List cartItems) {
  print('[Checkout] _buildOrderItems() called with ${cartItems.length} items');
  return Card(
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = cartItems[index];  // ← item は dynamic 型
        return ListTile(
          title: Text(item.menuItem.name),       // ← エラー発生箇所
          subtitle: Text('x${item.quantity}'),
          trailing: Text(
            '¥${item.totalPrice.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    ),
  );
}
```

### 根本原因

#### 問題1: 型の不明確さ

**282行目**: `Widget _buildOrderItems(List cartItems)`

- `List` に型パラメータがない
- `cartItems[index]` で取得した `item` は `dynamic` 型
- `dynamic` 型に対する `item.menuItem.name` アクセスは**実行時エラー**の可能性

#### 問題2: ListView.separated のレイアウト制約

**284-301行目**: `Card` > `ListView.separated`

- `Card` に高さ制約がない
- `ListView.separated` は `shrinkWrap: true` を使用
- しかし、`SingleChildScrollView` > `Column` > `Card` > `ListView.separated` の深いネスト構造
- レイアウト制約が正しく伝播せず、**RenderFlexエラー**の可能性

#### 問題3: itemBuilder内での例外

**290-299行目**: `itemBuilder` 内の処理

- `cartItems` の実際の型は `List<CartItem>`
- しかし型定義なしの `List` として受け取っている
- `item.menuItem`, `item.quantity`, `item.totalPrice` へのアクセス時に:
  - `NoSuchMethodError` が発生
  - または型キャストエラーが発生
  - Flutterがエラーをキャッチし、ErrorWidget表示を試みるが失敗

---

## 証拠

### 表示されているUI要素
- ✅ 黄色のテストコンテナ（185-189行目）
- ✅ "配達先住所" テキスト（191行目）
- ✅ "テスト: 住所セクション" Card（193行目の`_buildAddressSelector()`の結果）
- ✅ "注文内容" テキスト（195行目）

### 表示されていないUI要素
- ❌ 注文アイテムのリスト（197行目の`_buildOrderItems()`の結果）
- ❌ 以降のすべてのセクション

### ログ証拠
- ✅ `[Checkout] _buildOrderItems() called with 1 items` - メソッドは呼ばれた
- ❌ その後のログなし - return文でエラー

---

## 改善案

### 解決策1: 型を明示的に指定（推奨）

```dart
Widget _buildOrderItems(List<CartItem> cartItems) {  // ← 型パラメータ追加
  print('[Checkout] _buildOrderItems() called with ${cartItems.length} items');

  return Card(
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final CartItem item = cartItems[index];  // ← 型を明示
        return ListTile(
          title: Text(item.menuItem.name),
          subtitle: Text('x${item.quantity}'),
          trailing: Text(
            '¥${item.totalPrice.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    ),
  );
}
```

**変更点**:
- `List` → `List<CartItem>`
- `final item` → `final CartItem item`

---

### 解決策2: Padding追加（追加の安全策）

```dart
Widget _buildOrderItems(List<CartItem> cartItems) {
  print('[Checkout] _buildOrderItems() called with ${cartItems.length} items');

  return Card(
    child: Padding(  // ← Padding追加
      padding: const EdgeInsets.all(8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final CartItem item = cartItems[index];
          return ListTile(
            title: Text(item.menuItem.name),
            subtitle: Text('x${item.quantity}'),
            trailing: Text(
              '¥${item.totalPrice.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    ),
  );
}
```

---

### 解決策3: try-catchでエラーハンドリング（デバッグ用）

```dart
Widget _buildOrderItems(List<CartItem> cartItems) {
  print('[Checkout] _buildOrderItems() called with ${cartItems.length} items');

  try {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cartItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          try {
            final CartItem item = cartItems[index];
            print('[Checkout] Building item $index: ${item.menuItem.name}');
            return ListTile(
              title: Text(item.menuItem.name),
              subtitle: Text('x${item.quantity}'),
              trailing: Text(
                '¥${item.totalPrice.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          } catch (e, stack) {
            print('[Checkout] ERROR building item $index: $e');
            print('[Checkout] Stack: $stack');
            return ListTile(
              title: Text('エラー: アイテム $index'),
              subtitle: Text(e.toString()),
            );
          }
        },
      ),
    );
  } catch (e, stack) {
    print('[Checkout] ERROR in _buildOrderItems: $e');
    print('[Checkout] Stack: $stack');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('注文内容の読み込みに失敗しました: $e', style: TextStyle(color: Colors.red)),
      ),
    );
  }
}
```

このバージョンを使えば、**具体的なエラーメッセージとスタックトレースがログに出力**されます。

---

## 検証方法

### ステップ1: 型を明示（解決策1）を適用
1. `List` → `List<CartItem>` に変更
2. `final item` → `final CartItem item` に変更
3. 再ビルド
4. チェックアウト画面で確認

### ステップ2: エラーが解決しない場合
解決策3（try-catch版）を適用して、詳細なエラーメッセージを取得

---

## 補足: Stripe設定との関係

### 質問: 「stripeがこのお店側に設定されていないからではないのか」

**回答: いいえ、Stripe設定とは無関係です。**

#### 証拠:

1. **レストランID 2（寿司処 さくら）のデータ**:
   ```json
   {
     "id": 2,
     "name": "寿司処 さくら",
     "stripe_account_id": null,
     "stripe_onboarding_completed": false,
     "stripe_payouts_enabled": false
   }
   ```

2. **しかし、以下は正常に動作**:
   - ✅ レストラン詳細画面の表示
   - ✅ メニューの取得と表示
   - ✅ カートへの追加
   - ✅ チェックアウト画面への遷移
   - ✅ 配達先住所セクションの表示

3. **Stripe設定チェックは実装されていない**:
   - `checkout_screen.dart` には `isStripeFullySetup` チェックがない
   - レストランのStripe状態に関係なく、画面は表示されるべき

4. **エラー箇所はStripeと無関係**:
   - `_buildOrderItems()` はカートアイテムのリスト表示
   - Stripe APIやStripe状態は一切使用していない
   - 単純に `item.menuItem.name` などを表示しようとしているだけ

---

## 結論

### 確定した原因

**`_buildOrderItems()` メソッドの `ListView.separated` の `itemBuilder` 内で、`dynamic` 型の `item` に対してプロパティアクセスを試み、実行時エラーが発生している。**

### 推奨される修正

**解決策1（型の明示）を適用**:
- `List` → `List<CartItem>`
- `final item` → `final CartItem item`

### 次のステップ

1. 解決策1を実装
2. アプリを再ビルド
3. チェックアウト画面で動作確認
4. 解決しない場合、解決策3（try-catch版）で詳細エラーを取得

---

このファイルは原因分析と解決策をまとめたものです。
