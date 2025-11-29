# ボトムナビゲーションバー設計書

## 現状分析

### 現在のナビゲーション構造

**ホーム画面**:
```
┌─────────────────────────────────────┐
│ FoodHub          [カート] [👤]      │ AppBar
├─────────────────────────────────────┤
│ [検索バー]                          │
│ [カテゴリフィルター]                │
│ レストラン一覧                       │
│ - レストランカード                   │
│ - レストランカード                   │
│ - ...                               │
└─────────────────────────────────────┘
  bottomNavigationBar: なし ❌
```

**右上の👤ボタン → ダイアログ表示**:
- プロフィール
- 注文履歴
- お気に入り
- マイレビュー
- 住所管理
- ログアウト

### 問題点

1. **アクセス性が悪い**
   - 注文履歴を見るのに2タップ必要（👤ボタン → 注文履歴）
   - 重要機能が隠れている

2. **一貫性がない**
   - 各画面でナビゲーション方法が異なる
   - AppBarの戻るボタンのみ

3. **追跡機能にアクセスできない**
   - せっかく実装した追跡画面への導線がない

4. **モダンなUXではない**
   - 現代のフードデリバリーアプリはボトムナビが標準

---

## 設計方針

### コンセプト

**「今のレストラン一覧は維持しつつ、主要機能へのアクセスを改善」**

- 現在のホーム画面のデザイン・機能は保持
- ボトムナビゲーションバーを追加して主要機能への導線を追加
- 右上のプロフィールダイアログは**サブ機能用に残す**

---

## ボトムナビゲーションバー設計

### タブ構成（4タブ）

```
┌──────────────┬──────────────┬──────────────┬──────────────┐
│   [home]     │  [receipt]   │  [favorite]  │   [person]   │
│   ホーム      │   注文       │ お気に入り    │    その他     │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

### タブ詳細

#### タブ1: ホーム
- **アイコン**: `Icons.home` / `Icons.home_outlined`
- **ラベル**: "ホーム"
- **画面**: 現在の `HomeScreen`（レストラン一覧）
- **内容**: そのまま維持
  - 検索バー
  - カテゴリフィルター
  - レストラン一覧
  - AppBar: タイトル + カートアイコン + プロフィールアイコン

#### タブ2: 注文
- **アイコン**: `Icons.receipt_long` / `Icons.receipt_long_outlined`
- **ラベル**: "注文"
- **画面**: `OrderHistoryScreen`
- **内容**:
  - ステータスフィルター（既存）
  - 注文カード一覧
  - **各カードに「追跡」ボタン追加**（picked_up/delivering時のみ）

#### タブ3: お気に入り
- **アイコン**: `Icons.favorite` / `Icons.favorite_border`
- **ラベル**: "お気に入り"
- **画面**: `FavoritesScreen`
- **内容**: そのまま維持
  - お気に入りレストラン一覧
  - スワイプで削除

#### タブ4: その他
- **アイコン**: `Icons.menu` / `Icons.menu_outlined`
- **ラベル**: "その他"
- **画面**: 新規作成 `MenuScreen`
- **内容**:
  - プロフィール情報表示
  - メニュー一覧:
    - プロフィール編集
    - マイレビュー
    - 住所管理
    - パスワード変更
    - ログアウト

---

## 画面構成の変更

### 新規作成: MainNavigationScreen

```dart
// 新規ファイル: lib/features/customer/screens/main_navigation_screen.dart

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;  // 初期表示タブ（0-3）

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),           // タブ0: ホーム
    OrderHistoryScreen(),   // タブ1: 注文
    FavoritesScreen(),      // タブ2: お気に入り
    MenuScreen(),           // タブ3: その他（新規作成）
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: '注文',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'お気に入り',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'その他',
          ),
        ],
      ),
    );
  }
}
```

---

### 新規作成: MenuScreen（その他タブ）

```dart
// 新規ファイル: lib/features/customer/screens/menu_screen.dart

class MenuScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('メニュー'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          child: Column(
            children: [
              // プロフィールヘッダー
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 30),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'ゲスト',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '',
                          style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // メニューリスト
              _buildMenuItem(
                icon: Icons.edit,
                title: 'プロフィール編集',
                onTap: () => Navigator.pushNamed(context, '/customer/profile/edit'),
              ),
              _buildMenuItem(
                icon: Icons.rate_review,
                title: 'マイレビュー',
                onTap: () => Navigator.pushNamed(context, '/customer/my-reviews'),
              ),
              _buildMenuItem(
                icon: Icons.location_on,
                title: '住所管理',
                onTap: () => Navigator.pushNamed(context, '/customer/addresses/select'),
              ),
              _buildMenuItem(
                icon: Icons.lock,
                title: 'パスワード変更',
                onTap: () => Navigator.pushNamed(context, '/customer/password/change'),
              ),

              Divider(),

              _buildMenuItem(
                icon: Icons.logout,
                title: 'ログアウト',
                color: Colors.red,
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
                },
              ),
            ],
          ),
        ),
        loading: () => LoadingIndicator(),
        error: (e, _) => ErrorView(error: e),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
```

---

## 既存画面の変更

### 1. HomeScreen（ホーム画面）

**変更内容**:
- AppBarは維持（カート・プロフィールアイコン）
- `_showProfileDialog()` メソッドを**簡略化**または削除
- 右上の👤ボタンは**プロフィール直リンク**に変更

**理由**:
- メインナビゲーションはボトムナビに移行
- ダイアログは冗長になる

---

### 2. OrderHistoryScreen（注文履歴画面）

**変更内容**:
- 各注文カードに**「追跡」ボタン追加**
- 条件: `status == 'picked_up' || status == 'delivering'`

**実装イメージ**:
```dart
// _OrderCard ウィジェット内
if (['picked_up', 'delivering'].contains(order.status))
  Padding(
    padding: EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      icon: Icon(Icons.location_on, size: 18),
      label: Text('配達を追跡'),
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/customer/order-tracking/${order.id}',
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.black),
      ),
    ),
  )
```

---

### 3. OrderDetailScreen（注文詳細画面）

**変更内容**:
- ステータスカードの直下に**「配達を追跡」ボタン追加**
- 条件: `status == 'picked_up' || status == 'delivering'`

**実装イメージ**:
```dart
// _buildStatusCard の直後
if (['picked_up', 'delivering'].contains(order.status))
  Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: CustomButton(
      text: '配達を追跡',
      icon: Icons.location_on,
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/customer/order-tracking/${order.id}',
        );
      },
    ),
  )
```

---

### 4. FavoritesScreen（お気に入り画面）

**変更内容**: なし（そのまま）

---

## ルーティング変更

### main.dart の変更

```dart
// 変更前
initialRoute: AppRoutes.splash,
routes: {
  AppRoutes.splash: (context) => SplashScreen(),
  AppRoutes.login: (context) => LoginScreen(),
  AppRoutes.customerHome: (context) => HomeScreen(),  // ← これを変更
  ...
}

// 変更後
initialRoute: AppRoutes.splash,
routes: {
  AppRoutes.splash: (context) => SplashScreen(),
  AppRoutes.login: (context) => LoginScreen(),
  AppRoutes.customerHome: (context) => MainNavigationScreen(),  // ← 新規画面
  ...
}
```

---

## IndexedStack vs PageView の選択

### IndexedStack（推奨）

**メリット**:
- 各タブの状態を保持（スクロール位置など）
- タブ切り替えが瞬時
- 検索条件やフィルターが保持される

**デメリット**:
- 全タブが常にメモリにある（軽微）

### PageView

**メリット**:
- スワイプでタブ切り替え可能
- メモリ効率が良い

**デメリット**:
- タブの状態が失われる可能性
- スワイプジェスチャーが邪魔になることも

**結論**: **IndexedStack を採用**（UX優先）

---

## デザイン仕様

### BottomNavigationBar スタイル

```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,  // 4タブ固定
  backgroundColor: Colors.white,
  selectedItemColor: Colors.black,      // 選択時: 黒
  unselectedItemColor: Colors.grey[600], // 非選択時: グレー
  selectedFontSize: 12,
  unselectedFontSize: 12,
  elevation: 8,
  items: [...],
)
```

### アイコンの選択

| タブ | 非選択アイコン | 選択アイコン |
|------|--------------|------------|
| ホーム | `home_outlined` | `home` (塗りつぶし) |
| 注文 | `receipt_long_outlined` | `receipt_long` |
| お気に入り | `favorite_border` | `favorite` |
| その他 | `menu` | `menu` (同じ) |

---

## 機能配置の整理

### ボトムナビゲーション（メイン機能）

- ホーム（レストラン一覧・検索）
- 注文（注文履歴・追跡）
- お気に入り
- その他（設定系）

### AppBar（補助機能）

- カートアイコン（全タブ共通）
- プロフィールアイコン → プロフィール画面へ直リンク

### その他タブ内（詳細設定）

- プロフィール編集
- マイレビュー
- 住所管理
- パスワード変更
- ログアウト

---

## 画面遷移フロー

### 現在の遷移（問題あり）

```
スプラッシュ → ログイン → ホーム画面
                            │
                            ├→ [👤] → ダイアログ → 注文履歴
                            ├→ [👤] → ダイアログ → お気に入り
                            └→ レストラン詳細 → ...
```

**問題**: 注文履歴・お気に入りが2階層深い

---

### 新しい遷移（改善版）

```
スプラッシュ → ログイン → MainNavigationScreen
                            │
                            ├─ タブ0: ホーム
                            │   └→ レストラン詳細 → カート → チェックアウト → 注文確認
                            │
                            ├─ タブ1: 注文
                            │   ├→ 注文詳細 → [配達を追跡]
                            │   └→ 追跡画面（地図表示）
                            │
                            ├─ タブ2: お気に入り
                            │   └→ レストラン詳細
                            │
                            └─ タブ3: その他
                                ├→ プロフィール編集
                                ├→ マイレビュー
                                ├→ 住所管理
                                ├→ パスワード変更
                                └→ ログアウト
```

**改善点**: 注文履歴・お気に入りが1タップでアクセス可能

---

## 追跡ボタンの配置

### 注文履歴画面の各カード

```dart
Card(
  child: Column(
    children: [
      // 既存の注文情報表示
      ListTile(
        leading: [レストランロゴ],
        title: [レストラン名],
        subtitle: [注文番号・日時],
        trailing: [ステータスバッジ],
      ),

      // 注文アイテム表示
      [アイテム一覧],

      // 価格表示
      [合計金額],

      // アクションボタン行
      Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // 詳細ボタン（既存）
            Expanded(
              child: OutlinedButton(
                child: Text('詳細'),
                onPressed: () => [詳細画面へ],
              ),
            ),

            SizedBox(width: 8),

            // 追跡ボタン（新規・条件付き表示）
            if (status == 'picked_up' || status == 'delivering')
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.location_on, size: 18),
                  label: Text('追跡'),
                  onPressed: () => [追跡画面へ],
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
)
```

---

### 注文詳細画面

```dart
Column(
  children: [
    // ステータスカード
    _buildStatusCard(order),

    SizedBox(height: 16),

    // 追跡ボタン（新規・目立つ位置）
    if (['picked_up', 'delivering'].contains(order.status))
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: CustomButton(
          text: '配達を追跡',
          icon: Icons.location_on,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/customer/order-tracking/${order.id}',
            );
          },
          backgroundColor: Colors.black,
        ),
      ),

    SizedBox(height: 16),

    // レストラン情報カード
    _buildOrderInfoCard(order),

    // 注文内容カード
    _buildItemsCard(order),

    // ...
  ],
)
```

---

## 実装優先順位

### Phase 1: 追跡ボタンのみ追加（最優先）

**所要時間**: 20分

**ファイル変更**:
1. `order_history_screen.dart` - カードに追跡ボタン追加
2. `order_detail_screen.dart` - 追跡ボタン追加

**メリット**:
- 追跡機能がすぐ使える
- 最小限の変更

---

### Phase 2: ボトムナビゲーションバー追加（推奨）

**所要時間**: 1-2時間

**ファイル作成**:
1. `main_navigation_screen.dart`（新規）
2. `menu_screen.dart`（新規）

**ファイル変更**:
1. `main.dart` - ルーティング変更
2. `home_screen.dart` - プロフィールダイアログ簡略化

**メリット**:
- モダンなUX
- アクセス性向上
- 業界標準のUI

---

### Phase 3: 細かいUI改善（オプション）

**所要時間**: 1時間

**内容**:
- ボトムナビのアニメーション
- タブ間遷移のトランジション
- バッジ表示（未読通知など）

---

## 既存機能への影響

### 維持される機能

- レストラン一覧・検索（ホームタブ）
- カート機能（全タブ共通のAppBar）
- 注文フロー（そのまま）
- お気に入り機能（専用タブ化）
- プロフィール管理（その他タブ）

### 削除される要素

- 右上👤ボタンのダイアログメニュー
  → ボトムナビ + その他タブに置き換え

### 改善される点

- 注文履歴へのアクセス: 2タップ → 1タップ
- お気に入りへのアクセス: 2タップ → 1タップ
- 追跡機能へのアクセス: 不可能 → 1-2タップ

---

## まとめ

### 現状

- ボトムナビゲーションバー: **なし**
- 主要機能: プロフィールダイアログに集約
- 追跡ボタン: **なし**（機能が使えない状態）

### 推奨実装

**最小限（Phase 1）**:
- 注文履歴・詳細画面に追跡ボタン追加のみ

**完全版（Phase 2）**:
- 4タブのボトムナビゲーション
- その他タブに設定系を集約
- 追跡ボタンも同時に追加

### あなたの要望との整合性

- 今のレストラン一覧（ダッシュボード）: **完全に維持**
- フッター追加: **設計完了**
- 右上のユーザーボタン: **簡略化して残す**（プロフィール直リンク）

この設計で実装を進めてよろしいでしょうか？
