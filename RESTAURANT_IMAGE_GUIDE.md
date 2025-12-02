# レストラン写真管理ガイド

## レストランの画像フィールド

レストランには2つの画像フィールドがあります：

### 1. coverImageUrl（カバー画像）
**用途**: 顧客ホーム画面で表示される大きなヘッダー画像
**サイズ**: 幅100%、高さ160px
**表示場所**:
- 顧客アプリのホーム画面
- レストラン一覧カード
- レストラン詳細画面のヘッダー

**表示ファイル**: `food_hub/lib/shared/widgets/restaurant_card.dart:33-60`

### 2. logoUrl（ロゴ画像）
**用途**: レストランのロゴ（現在未使用）
**将来の用途**: プロフィール画像、小さいアイコン表示など

---

## 現在の状態

### データベース
```sql
SELECT id, name, cover_image_url, logo_url FROM restaurants WHERE id = 1;

結果:
id: 1
name: イタリアンビストロ
cover_image_url: NULL
logo_url: NULL
```

### 顧客ホーム画面での表示
**cover_image_urlがNULLの場合**:
- グレーの背景（Colors.grey[200]）
- レストランアイコン（Icons.restaurant）が中央に表示

**cover_image_urlが設定されている場合**:
- 画像が160px高さで表示
- CachedNetworkImageで読み込み（キャッシュ対応）
- エラー時はグレー背景+アイコン

---

## レストラン写真を設定する方法

### 方法1: 直接DBを更新（現在の方法）
```sql
UPDATE restaurants
SET cover_image_url = 'https://example.com/restaurant-cover.jpg'
WHERE id = 1;
```

### 方法2: レストラン管理画面を実装（未実装）
現在、レストラン側で自分の写真を変更する画面はありません。

**実装する場合に必要なもの**:
1. レストランプロフィール編集画面
2. 画像アップロード機能（既に実装済み）
   - API: `POST /api/upload/restaurant-images`
   - Service: `ImageUploadService.uploadRestaurantImages()`
3. レストラン更新API（既に存在）
   - `PUT /api/restaurant/profile`

---

## アップロード済み画像の保存先

### メニュー画像
```
/root/uber/foodhub-backend/uploads/menu-items/
→ 公開URL: https://133-117-77-23.nip.io/uploads/menu-items/menu-1234567890-123456789.jpg
```

### レストラン画像
```
/root/uber/foodhub-backend/uploads/restaurants/
→ 公開URL: https://133-117-77-23.nip.io/uploads/restaurants/restaurant-1234567890-123456789.jpg
```

---

## 画像アップロードAPI

### メニュー画像アップロード
```
POST /api/upload/menu-images
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- images: File[] (最大10枚)

Response:
{
  "message": "Images uploaded successfully",
  "image_urls": [
    "https://133-117-77-23.nip.io/uploads/menu-items/menu-xxx.jpg",
    "https://133-117-77-23.nip.io/uploads/menu-items/menu-yyy.jpg"
  ]
}
```

### レストラン画像アップロード
```
POST /api/upload/restaurant-images
Content-Type: multipart/form-data
Authorization: Bearer {token}

Body:
- images: File[] (最大5枚)

Response:
{
  "message": "Images uploaded successfully",
  "image_urls": [
    "https://133-117-77-23.nip.io/uploads/restaurants/restaurant-xxx.jpg"
  ]
}
```

### 画像削除
```
DELETE /api/upload/image
Content-Type: application/json
Authorization: Bearer {token}

Body:
{
  "image_url": "https://133-117-77-23.nip.io/uploads/menu-items/menu-xxx.jpg"
}
```

---

## 実装済み機能

### ✅ メニュー画像
- 画像ピッカーUI（最大10枚選択可能）
- 複数画像プレビュー表示
- 画像削除機能
- 自動アップロード（メニュー保存時）
- メニュー追加画面: `restaurant_menu_add_screen.dart`
- メニュー編集画面: `restaurant_menu_edit_screen.dart`

### ❌ レストラン写真（未実装）
レストランプロフィール編集画面が存在しないため、現在は手動でDBを更新する必要があります。

---

## テスト用画像URL（例）

無料画像サービスのURL例:
```
https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800
https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800
https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800
```

またはローカルにアップロード:
```
POST /api/upload/restaurant-images
→ https://133-117-77-23.nip.io/uploads/restaurants/restaurant-xxx.jpg
```

---

## 今後の実装推奨

### レストランプロフィール編集画面
```dart
// 画面構成
- カバー画像変更
- ロゴ画像変更
- 店名、説明、カテゴリ編集
- 営業時間設定
- 配達設定（配達料、配達範囲）

// 実装ファイル
lib/features/restaurant/screens/restaurant_profile_edit_screen.dart
```

この画面を実装すれば、レストラン側で自由に写真を変更できます。
