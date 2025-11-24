# FoodHub Backend API

Uber Eats風フードデリバリーアプリのバックエンドAPI

## 🚀 起動方法

```bash
# 開発モード（自動リロード）
npm run dev

# 本番モード
npm start
```

## 📡 APIエンドポイント

### 認証 (Authentication)

#### ログイン
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "customer@test.com",
  "password": "password123",
  "user_type": "customer"  # "customer", "restaurant", "driver"
}
```

#### 新規登録（顧客）
```bash
POST /api/auth/register/customer
Content-Type: application/json

{
  "email": "newcustomer@example.com",
  "password": "yourpassword",
  "full_name": "山田太郎",
  "phone": "080-1234-5678"
}
```

#### 新規登録（レストラン）
```bash
POST /api/auth/register/restaurant
Content-Type: application/json

{
  "email": "restaurant@example.com",
  "password": "yourpassword",
  "name": "レストラン名",
  "description": "説明",
  "category": "Japanese",
  "phone": "03-1234-5678",
  "address": "東京都渋谷区...",
  "latitude": 35.6581,
  "longitude": 139.7017
}
```

#### 新規登録（配達員）
```bash
POST /api/auth/register/driver
Content-Type: application/json

{
  "email": "driver@example.com",
  "password": "yourpassword",
  "full_name": "佐藤花子",
  "phone": "090-1234-5678",
  "vehicle_type": "Motorcycle",
  "license_number": "12345678"
}
```

#### 現在のユーザー情報取得
```bash
GET /api/auth/me
Authorization: Bearer {your_jwt_token}
```

## 🧪 テストユーザー

### 顧客
- **Email**: customer@test.com
- **Password**: password123
- **User Type**: customer

### レストラン
- **Email**: restaurant@test.com
- **Password**: password123
- **User Type**: restaurant

### 配達員
- **Email**: driver@test.com
- **Password**: password123
- **User Type**: driver

## 📁 プロジェクト構造

```
src/
├── config/          # 設定ファイル（DB等）
├── controllers/     # ビジネスロジック
├── middleware/      # 認証等のミドルウェア
├── models/          # Sequelizeモデル
├── routes/          # APIルート定義
├── utils/           # ユーティリティ（JWT, パスワード等）
└── app.js           # メインアプリケーション

database/
└── schema.sql       # データベーススキーマ

scripts/
└── updateTestUsers.js  # テストユーザーパスワード更新
```

## 🗄️ データベース

### 接続情報
- **Host**: localhost
- **Port**: 3306
- **Database**: foodhub
- **User**: root
- **Password**: (環境変数 `.env` で設定)

### スキーマ更新
```bash
mysql -u root -p foodhub < database/schema.sql
```

## 🔐 環境変数

`.env` ファイル:
```
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_PORT=3306
DB_NAME=foodhub
DB_USER=root
DB_PASSWORD=your_password

JWT_SECRET=your_secret_key
BCRYPT_ROUNDS=10

STRIPE_SECRET_KEY=sk_test_...
```

## 📦 依存パッケージ

- **express**: Webフレームワーク
- **sequelize**: ORM
- **mysql2**: MySQLドライバー
- **bcrypt**: パスワードハッシュ化
- **jsonwebtoken**: JWT認証
- **express-validator**: バリデーション
- **dotenv**: 環境変数管理
- **cors**: CORS設定
- **socket.io**: リアルタイム通信（今後実装）
- **stripe**: 決済処理（今後実装）

## 🔄 次回の開始時

```bash
# 1. サーバー起動
cd C:\Users\genki\Projects\app\uber\foodhub-backend
npm run dev

# 2. APIテスト（別ターミナル）
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@test.com","password":"password123","user_type":"customer"}'
```

## ✅ 実装済み機能

- [x] データベーススキーマ
- [x] ユーザーモデル（Customer, Restaurant, Driver）
- [x] JWT認証
- [x] パスワードハッシュ化
- [x] ログインAPI
- [x] 新規登録API（3タイプ）
- [x] 認証ミドルウェア

## 🚧 次のステップ

- [ ] APIエンドポイントテスト完了
- [ ] Flutterログイン画面実装
- [ ] レストラン一覧API
- [ ] 注文API
