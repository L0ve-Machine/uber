# ASVS L1 チェックリスト実施記録

- 案件: foodhub / `foodhub-backend` (フードデリバリー・バックエンド API)
- 実施日: 2026-08-29
- 実施者: Claude Code (security-checklist skill) / 確認: (未記入)
- 対象範囲: `foodhub-backend/` (Node.js / Express バックエンド)。Flutter クライアント `food_hub/` は利用エンドポイントと鍵の取り扱い確認のみ。`foodhub-backend/node_modules` はスキャン対象外。
- 技術スタック: Node.js / Express 5.1 / Sequelize 6.37 + mysql2 (MySQL) / jsonwebtoken 9 (Bearer JWT) / bcrypt 6 / multer 2 / socket.io 4.8 / stripe 20 (Payment Intents + Stripe Connect Express) / express-validator 7。フロントは Flutter (Dart)。LLM 機能なし。
- 本番構成: pm2 (root 実行) で `node /root/uber/foodhub-backend/src/app.js` を :3000 で起動。ホスト nginx が `133-117-77-23.nip.io` → `localhost:3000` (`/socket.io/` 含む) をリバースプロキシ。3000/3001 は外部から直接到達不可。
- 集計: ○ 8 / × 15 / — 11 / ? 1

> **総評: 本番リリース可の状態ではない。** 決済まわりに金銭的被害に直結する欠陥が 2 件 (P-1 オプション価格のクライアント制御、P-2 支払い成否の未検証)、認証まわりに JWT 署名鍵がプレースホルダのまま (V3.2) という致命的欠陥がある。V3.2 は「任意ユーザー・任意ロールになりすませる」ことを意味し、他のすべてのアクセス制御を無効化する。最優先で対処すること。

---

## 判定一覧

| # | 分類 | 項目 | 判定 | 根拠 / 指摘 | 修正方針 |
|---|---|---|---|---|---|
| V2.1 | 認証 | パスワードを bcrypt/argon2/scrypt でハッシュ化 | ○ | `src/utils/password.js:10` `bcrypt.hash(password, rounds)`、`:20` `bcrypt.compare`。コスト値は `.env:30` `BCRYPT_ROUNDS=10`。全登録経路が経由 (`src/controllers/authController.js:110,173,245`) | (コスト 12 への引き上げは任意) |
| V2.2 | 認証 | ログイン・リセット等にレート制限/ロックアウト | × | `express-rate-limit` 等が `package.json:14-26` に存在せず、`src/` 全体に該当実装なし。`POST /api/auth/login` (`src/routes/auth.js:54`)、`POST /api/driver/orders/:id/verify-pin` (`src/routes/driver.js:75`) が無制限 | `express-rate-limit` を導入し `/api/auth/*` に 5req/15min、`verify-pin` に 5req/10min を適用 |
| V2.3 | 認証 | 認証情報をログ・エラー・URL に出さない | × | ピックアップ PIN を平文でログ出力: `src/controllers/driverController.js:417` (`expected=${order.pickup_pin}`)、`src/controllers/restaurantDashboardController.js:265`。加えて本番 `.env:3` が `NODE_ENV=development` のため `src/config/database.js:12` が全 SQL を `console.log` し、`password_hash` を含む INSERT/UPDATE が pm2 ログに残る | PIN のログ出力を削除。`NODE_ENV=production` にして SQL ログを無効化 |
| V2.4 | 認証 | パスワード最低長 8 以上 | × | 登録時は最低 6 文字: `src/routes/auth.js:20`(customer)、`:28`(restaurant)、`:41`(driver) `isLength({ min: 6 })`。一方パスワード変更は 8 文字 (`src/routes/driver.js:30`、`src/routes/restaurant.js:39`) で不整合 | 登録側 3 箇所を `min: 8` に統一 |
| V2.5 | 認証 | 初期パスワード・テストアカウントが本番に残っていない | × | `seed-data.js:10` で全テストアカウントに `password123` を設定し、`:14,49,69,89,273` で `customer@test.com` / `restaurant@test.com` / `sushi@test.com` / `burger@test.com` / `driver@test.com` を作成。`scripts/updateTestUsers.js:15-34` も同一パスワードに再設定する。両ファイルが本番ツリー `/root/uber/foodhub-backend/` に配置されている | 本番 DB で該当 5 アカウントの存在を確認し削除。両スクリプトを本番から除去するか `NODE_ENV=production` でガード |
| V3.1 | セッション | Cookie に HttpOnly/Secure/SameSite | — | Cookie セッションを使用していない。認証は Authorization ヘッダの Bearer JWT のみ (`src/middleware/auth.js:10-15`)。`res.cookie` / `cookie-parser` の使用箇所なし |  |
| V3.2 | セッション | JWT 署名鍵が環境変数から読まれハードコードされていない | × | 読み込み自体は環境変数経由で正しい (`src/utils/jwt.js:9,21` `process.env.JWT_SECRET`)。**しかし本番 `.env:13` の値が `JWT_SECRET=your_jwt_secret_key_change_this_in_production_12345` というプレースホルダのまま。** リポジトリに `.env.example` は存在せず (`ls .env*` は `.env` のみ)、この文字列は雛形由来の推測可能な既知値である。第三者がこの値で任意の `{id, email, user_type}` を署名すれば、任意の顧客・店舗・配達員になりすませ、V4.x のアクセス制御がすべて無効化される | `node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"` で生成した値に即時差し替え、サーバー再起動 (既発行トークンは全失効)。あわせて `.env.example` をプレースホルダのみで整備 |
| V3.3 | セッション | ログアウトでサーバー側セッション/JWT が失効 | × | ログアウト用エンドポイントが存在しない (`src/routes/auth.js` は login / register×3 / me のみ)。JWT ブラックリスト・`jti`・トークンバージョン列のいずれも無し。有効期限 7 日 (`src/utils/jwt.js:10`) のため、端末紛失・パスワード変更後も最大 7 日間トークンが有効なまま | 有効期限を 1〜24 時間に短縮 + リフレッシュトークン、または各ユーザー表に `token_version` を持たせて `verifyToken` 後に照合 |
| V3.4 | セッション | JWT: alg none 不許可・有効期限あり・署名検証 | ○ | `src/utils/jwt.js:10` `expiresIn: '7d'`、`:21` `jwt.verify(token, secret)` で署名検証。秘密鍵が文字列のため jsonwebtoken 側で HMAC 系のみ許容され `alg: none` は拒否される。※ V3.2 により署名検証は実質無意味な点に注意 | (任意) `jwt.verify(token, secret, { algorithms: ['HS256'] })` と明示 |
| V4.1 | アクセス制御 | 全ての状態変更エンドポイントに認証ミドルウェア | × | HTTP ルート 74 本は全数確認済みで問題なし (付録 A)。認証なしの状態変更は login/register×3 (仕様上公開) と Stripe Webhook (署名検証で代替) のみ。**一方 Socket.IO の状態変更イベントが完全に無認証**: `src/app.js:110-121` `driver:location-update` はハンドラ内で `Driver.update({...}, { where: { id: driverId } })` を実行するが、`driverId` はクライアント送信値をそのまま使用し検証が一切ない | 下記「× 項目の詳細」参照 |
| V4.2 | アクセス制御 | リソース所有者チェック (IDOR 対策) | × | 大半は適切 (付録 B)。**例外 2 件**: ① `src/controllers/uploadController.js:62-84` `DELETE /api/upload/image` が `image_url` から抽出したファイル名を所有者確認なしに削除するため、任意の店舗アカウントが他店舗の画像を削除可能。② 上記 Socket.IO による他配達員の位置改ざん | 下記「× 項目の詳細」参照 |
| V4.3 | アクセス制御 | ロール昇格がサーバー側で検証されている | ○ | ロールは署名済み JWT の `user_type` のみを参照し (`src/middleware/auth.js:33,43,53`)、リクエストボディの値は一切信用していない。`user_type` はログイン時にサーバーが決定 (`src/controllers/authController.js:61-65`)。※ 別途「店舗・配達員の自動承認」の懸念あり (追加所見 A-1) |  |
| V4.4 | アクセス制御 | CSRF 対策 | — | Cookie セッションを使用しておらず、認証情報はブラウザが自動送信しない Authorization ヘッダのみ。クライアントもネイティブ Flutter アプリのため CSRF は成立しない |  |
| V4.5 | アクセス制御 | 管理画面・内部 API が URL 秘匿のみで保護されていない | — | 管理者ロール・管理画面・管理 API が実装されていない (`isAdmin` 等は存在しない)。※ 店舗/配達員の承認を行う管理機能が無いこと自体は追加所見 A-1 で指摘 |  |
| V5.1 | 入力検証 | SQL はプレースホルダ / ORM | ○ | 全コントローラが Sequelize のオブジェクト構文を使用し、文字列連結でのクエリ組み立ては皆無 (`sequelize.query` の全出現は `init-database.js:15` の静的文字列 `"SHOW TABLES"` のみ)。`Op.like` 検索も値バインド (`src/controllers/restaurantController.js:28-29`)。`scripts/updateTestUsers.js:19-34` も `?` プレースホルダ使用 |  |
| V5.2 | 出力エンコード | HTML 出力の自動エスケープ / サニタイズ | — | API は JSON のみを返す。HTML を返すのは Stripe オンボーディング復帰用の 4 ページ (`src/routes/stripeConnect.js:50,81,106,137`) のみで、テンプレートリテラル内にユーザー入力の埋め込みは無い (`${` の出現ゼロ、確認済み) |  |
| V5.3 | 入力検証 | OS コマンドにユーザー入力が渡っていない | — | `child_process` / `exec` / `spawn` の使用箇所なし (`src/` 全体で該当ゼロ) |  |
| V5.4 | 入力検証 | パストラバーサル対策 | ○ | ユーザー入力からファイルパスを組む唯一の箇所 `src/controllers/uploadController.js:71` で `path.basename(image_url)` により正規化。フォルダ名も `:74-77` で `menu-items` / `restaurants` の二択に固定され、`:79` の `path.join` は `uploads/` 配下に限定される | (パス自体は安全。ただし所有者チェック欠如は V4.2 参照) |
| V5.5 | 入力検証 | ファイルアップロードの検証 | ○ | 拡張子と MIME の二重チェック (`src/config/multer.js:27-37`)、サイズ上限 5MB / 枚数上限 10・5 枚 (`:42-46,50-54`)、保存名はサーバー生成で `Date.now()`+乱数+元拡張子のみ使用しユーザー入力を含まない (`:10-11,21-22`)。※ 保存先 `uploads/` は `src/app.js:29` で静的公開されるが、これはメニュー画像配信という仕様上の要件。拡張子ホワイトリストにより `.html` / `.svg` は保存不可 | (任意) `destination` が相対パス (`src/config/multer.js:7,17`) のため pm2 の cwd 依存。絶対パス化を推奨 |
| V5.6 | 入力検証 | SSRF 対策 | — | ユーザー指定 URL を取得する処理が存在しない (`fetch` / `axios` / `http.get` の使用箇所ゼロ)。外部通信は Stripe SDK のみで宛先は固定 |  |
| V5.7 | 入力検証 | リクエストボディのサイズ上限 | ○ | `src/app.js:25-26` `express.json()` / `express.urlencoded()` は Express 既定の 100kb 上限が適用される。ファイルは multer 側で 5MB 上限 (`src/config/multer.js:42`) | (任意) `express.json({ limit: '100kb' })` と明示して意図を固定 |
| V6.1 | 暗号・通信 | API キー等が .env/Secrets 管理でリポジトリに無い | ○ | `.env` は Git 未追跡 (`git ls-files --error-unmatch foodhub-backend/.env` → not known to git)、`.gitignore:1-4` で `.env` / `*.env` / `.env.*` を除外。Git 履歴の全走査 (`git log --all -S sk_test` / `-S whsec_` / `-S AIzaSy`) でヒットしたのは初回コミット `44fecd5` のみで、内容は Markdown ドキュメント中のプレースホルダ (`sk_test_YOUR_SECRET_KEY`、`whsec_xxx`、`sk_test_...`) であり実鍵の漏洩は無い。Stripe 鍵は全て **test** 鍵。Flutter 側に埋め込まれているのは公開鍵のみ (`food_hub/lib/shared/constants/app_constants.dart:7` `pk_test_...`) で仕様通り | (要対応) `.env:27` の `GOOGLE_MAPS_API_KEY` はバックエンド・Flutter とも参照箇所ゼロの未使用鍵。追加所見 A-3 参照 |
| V6.2 | 暗号・通信 | トークン等の乱数に crypto.randomBytes を使う | × | ピックアップ PIN が `src/utils/pinGenerator.js:10` `Math.floor(1000 + Math.random() * 9000)` で生成される。PIN は配達員が店舗で商品を受け取る際の本人確認用の**セキュリティ統制**であり、`Math.random` は暗号学的に安全でない | `crypto.randomInt(1000, 10000)` に置換。あわせて V2.2 のレート制限を `verify-pin` に適用 (現状 4 桁 = 9000 通りを無制限に試行可能) |
| V9.1 | 暗号・通信 | 本番は HTTPS 強制 | ? | アプリ側は全通信が HTTPS (`food_hub/lib/shared/constants/app_constants.dart:3-4` `https://133-117-77-23.nip.io`)、cleartext 許可設定も無し (`usesCleartextTraffic` / `NSAllowsArbitraryLoads` の記述ゼロ)。TLS 終端はホスト nginx 側でコード外のため未確認 | サーバーで `nginx -T \| grep -E "listen 443\|return 301\|Strict-Transport-Security"` を実行し、80→443 リダイレクトと HSTS ヘッダの有無を確認 |
| V7.1 | エラー処理 | 本番でスタックトレース・内部情報を返さない | × | `src/app.js:76` が `NODE_ENV === 'development'` のとき `err.message` をクライアントに返す設計だが、**本番 `.env:3` が `NODE_ENV=development`** のため本番で内部エラーが露出する。さらに `src/config/database.js:12` が同条件で全 SQL をログ出力。加えて Stripe 例外の生メッセージを常時返す箇所が 3 件: `src/controllers/orderController.js:589`、`src/controllers/stripeConnectController.js:67,127` (`details: error.message`) | 本番 `.env` を `NODE_ENV=production` に変更 + pm2 再起動。`details: error.message` の 3 箇所を削除 |
| V7.2 | エラー処理・ログ | 認証成否・権限エラー・管理操作の監査ログ | × | 監査ログの仕組みが無く、`console.error` によるエラー出力のみ。ログイン成功/失敗 (`src/controllers/authController.js:41,57`)、403 権限エラー (`src/middleware/auth.js:34,44,54`) はいずれも記録されない。誰が・いつ注文ステータスを変更したか、返金・送金を実行したかの追跡が不可能。逆に出してはいけない PIN は出力されている (V2.3) | ログイン成否・403・注文ステータス変更・返金/送金に「いつ・誰が (user_type+id)・何を」を出力する監査ログを追加 (秘密情報は除外) |
| V13.1 | API・設定 | CORS が `*` + credentials でない / 許可オリジンを列挙 | × | `src/app.js:24` `app.use(cors())` はオプション無しのため全オリジン許可 (`Access-Control-Allow-Origin: *`)。Socket.IO も `src/app.js:16` で `origin: '*'` (コメントに「In production, specify allowed origins」と書かれたまま未対応)。Cookie 非使用のため即座の認証情報漏洩には至らないが、任意の Web ページからブラウザ経由で API を叩ける | `cors({ origin: [process.env.APP_URL], methods: [...] })` に限定。Socket.IO も同様。Flutter ネイティブからの通信に CORS は不要なため、実質全拒否でも動作する |
| V14.1 | API・設定 | セキュリティヘッダ (helmet 等) | × | `helmet` が `package.json` に無く、`src/app.js` にヘッダ設定も無い。`X-Content-Type-Options` / `X-Frame-Options` (または CSP `frame-ancestors`) / `Referrer-Policy` がいずれも未設定。`/uploads/*` の静的配信 (`src/app.js:29`) と Stripe 復帰用 HTML ページ (`src/routes/stripeConnect.js:50,81,106,137`) はブラウザで開かれる想定のため影響を受ける | `npm i helmet` して `app.use(helmet())` を `src/app.js:24` 付近に追加 |
| V14.2 | API・設定 | 課金を伴う外部 API 呼び出しに認証とレート制限 | × | Stripe 呼び出しは全て認証済みだがレート制限が無い。特に `POST /api/stripe/connect/restaurant` / `/connect/driver` (`src/routes/stripeConnect.js:12,24`) は 1 リクエストごとに `stripe.accounts.create` (`src/controllers/stripeConnectController.js:27,92`) と `accountLinks.create` を呼ぶ。`POST /api/orders/:id/create-payment-intent` (`src/routes/orders.js:65`) も同様。自己登録した店舗アカウントから連打すれば Stripe API のレート制限到達・アカウント大量生成が可能。※ Google Maps は未使用のため課金対象外 (追加所見 A-3) | V2.2 のレート制限を Stripe 系エンドポイントにも適用 (例: 10req/hour) |
| V14.3 | API・設定 | デバッグ用エンドポイント・console.log での秘密出力が残っていない | × | HTTP のデバッグ用ルートは存在しない (`seed-data.js` / `init-database.js` はどのルータからも参照されず外部到達不可、確認済み)。しかし ① 秘密情報の `console.log` が残存 (PIN: `src/controllers/driverController.js:417`、`src/controllers/restaurantDashboardController.js:265` / 全 SQL: `src/config/database.js:12`)、② `init-database.js:11` が `sequelize.sync({ force: true })` (全テーブル DROP) を実行する状態で本番ツリーに存在、③ `node_modules` が 5,930 ファイル Git 追跡されている、④ `.claude/settings.local.json` 等 3 件が追跡されている | ①を削除。②を本番ツリーから除去するか `force: false` に変更。③④は `.gitignore` に既に記載があるため `git rm -r --cached foodhub-backend/node_modules` で追跡解除 |
| V14.4 | API・設定 | コンテナは非 root ユーザーで実行 | — | Dockerfile / docker-compose を使用しておらず、pm2 による直接起動のためコンテナ項目は非該当。※ ただし pm2 が **root** で `node /root/uber/foodhub-backend/src/app.js` を実行しており、RCE 時の被害が最大化する構成。ASVS L1 の範囲外だが運用上の指摘として記録 | (推奨) 専用一般ユーザーを作成し `pm2 startup` を該当ユーザーで再設定。アプリを `/root/` 配下から移動 |
| L-1 | LLM | プロンプトインジェクション対策 | — | LLM / 生成 AI 機能なし (`package.json` に該当依存なし) |  |
| L-2 | LLM | LLM 出力の HTML エスケープ | — | 同上 |  |
| L-3 | LLM | 依存パッケージの実在性 (typosquat) | — | 同上。※ 通常依存 11 件はいずれも著名パッケージで異常なし |  |
| L-4 | LLM | LLM に渡すデータのテナント分離 | — | 同上 |  |

---

## × 項目の詳細

### V3.2 JWT 署名鍵がプレースホルダのまま【最優先】
本番 `.env:13`:
```
JWT_SECRET=your_jwt_secret_key_change_this_in_production_12345
```
`src/utils/jwt.js:9,21` は環境変数から読む実装自体は正しいが、値が雛形の文言そのものである。リポジトリに `.env.example` が存在しないため「サンプルからのコピー漏れ」を証跡で示すことはできないが、`your_..._change_this_in_production_...` という文言は明らかにプレースホルダであり、公開されている多数のチュートリアル・雛形と同型で推測可能。

**影響**: 攻撃者がこの秘密鍵で `{ id: 1, email: "...", user_type: "restaurant" }` を HS256 署名すれば、`src/middleware/auth.js:18` の検証を通過する。ログイン不要で任意の顧客の注文・住所閲覧、任意店舗としての売上閲覧・メニュー改変、任意配達員としての配達受注が可能になり、本チェックリストの V4.x で ○ とした所有者チェックはすべて「なりすまし済みの正しい所有者」として突破される。

**修正**: 乱数 48 バイト以上に差し替え、pm2 再起動。既存トークンは全て無効化される (再ログインが必要)。あわせて `.env.example` を作成し、実値を含まないプレースホルダのみを記載する。

### V4.1 Socket.IO の状態変更イベントが完全に無認証
`src/app.js:94-149`。Socket.IO 接続時のハンドシェイク認証 (`io.use(...)`) が無く、各イベントハンドラにも検証が無い。

```js
// src/app.js:98-107
socket.on('driver:register', async (data) => {
  const { driverId, token } = data;   // ← token を受け取るが一切検証していない
  activeDrivers.set(driverId, socket.id);
  socket.driverId = driverId;
  socket.join(`driver-${driverId}`);
  socket.emit('driver:registered', { success: true });
});

// src/app.js:110-121
socket.on('driver:location-update', async (data) => {
  const { driverId, latitude, longitude } = data;   // ← 送信者と driverId の一致を検証していない
  await Driver.update(
    { current_latitude: latitude, current_longitude: longitude },
    { where: { id: driverId } }
  );
```

クライアント側は正しく JWT を送っている (`food_hub/lib/features/driver/services/background_location_service.dart:97` で `Authorization: Bearer` ヘッダ、`:108-111` で `token` をペイロードに同梱) が、**サーバーが受け取って捨てている**。

**影響**:
1. 未認証の第三者が `wss://133-117-77-23.nip.io/socket.io/` に接続し (nginx がプロキシしているため外部到達可能)、任意の `driverId` の位置を書き換えられる。この値は `src/controllers/orderController.js:474-478` の配達追跡 API がそのまま顧客に返すため、配達中の顧客に虚偽の位置を表示できる。
2. `src/app.js:140` の `io.emit` は**ルーム指定なしの全接続ブロードキャスト**のため、接続しただけの誰もが全配達員の位置更新 (ぼかし後 200m 精度) を受信できる。`socket.join('driver-...')` (`:104`) でルームを作っているが送信側で使われていない。

**修正**:
```js
io.use((socket, next) => {
  const token = socket.handshake.auth?.token
    || socket.handshake.headers.authorization?.replace(/^Bearer /, '');
  try {
    const decoded = verifyToken(token);
    if (decoded.user_type !== 'driver') return next(new Error('forbidden'));
    socket.user = decoded;
    next();
  } catch { next(new Error('unauthorized')); }
});
```
各ハンドラでは `data.driverId` を無視し `socket.user.id` を使用する。ブロードキャストは `io.emit` をやめ、該当注文の顧客が入るルーム (例 `order-${orderId}`) への `io.to(...).emit` に限定する。

### V4.2 画像削除エンドポイントに所有者チェックが無い
`src/controllers/uploadController.js:62-84` / ルート `src/routes/upload.js:45`。`router.use(authMiddleware)` `router.use(isRestaurant)` (`src/routes/upload.js:9-10`) により「ログイン済みの店舗である」ことは保証されるが、**削除対象がその店舗の画像かを一切確認していない**。

```js
const { image_url } = req.body;
const filename = path.basename(image_url);       // :71 traversal は防げている
let folder = 'menu-items';
if (image_url.includes('/restaurants/')) folder = 'restaurants';   // :74-77
const filePath = path.join(__dirname, '../../uploads', folder, filename);  // :79
await fs.unlink(filePath);                        // :84 所有者確認なしで削除
```
ファイル名は `menu-<13桁ミリ秒>-<9桁乱数>.jpg` 形式 (`src/config/multer.js:10-11`) だが、`GET /api/restaurants/:id/menu` は公開エンドポイント (`src/routes/restaurants.js:27`) で `image_url` をそのまま返すため、攻撃者は列挙不要で全店舗の実ファイル名を取得できる。自分の店舗アカウント 1 つで競合店のメニュー画像を全削除可能。

**修正**: `MenuItem.findOne({ where: { image_url, restaurant_id: req.user.id } })` で自店舗のレコードに紐づくことを確認してから `unlink` する。店舗画像側は `Restaurant.findByPk(req.user.id)` の `cover_image_url` / `logo_url` と突き合わせる。

### V2.2 レート制限が全く存在しない
`package.json:14-26` に `express-rate-limit` 等が無く、`src/` にも実装が無い。特に危険な 3 経路:
- `POST /api/auth/login` (`src/routes/auth.js:54`) — パスワード総当たり。アカウントロックも無し。
- `POST /api/driver/orders/:id/verify-pin` (`src/routes/driver.js:75`) — **4 桁 PIN (9000 通り) を無制限試行可能**。`src/controllers/driverController.js:416` の照合は試行回数を数えず、失敗しても状態を変えない。V6.2 (`Math.random`) と併せ、ピックアップ認証は実質機能していない。
- `POST /api/auth/register/*` (`src/routes/auth.js:61,72,83`) — アカウント大量作成。V14.2・追加所見 A-1 と連動。

**修正**: `express-rate-limit` を導入し、`/api/auth/*` に 5req/15min (IP+email 単位)、`verify-pin` に 5req/10min (超過時は注文を要店舗確認状態にする)、Stripe 系に 10req/hour を適用。

### V2.3 / V7.1 / V14.3 本番が development モードで動作している
本番 `.env:3` が `NODE_ENV=development`。これ 1 つで以下が同時に発生する:
- `src/app.js:76` — 500 応答に `err.message` が含まれ、内部構造・Sequelize のエラー詳細が露出。
- `src/config/database.js:12` — `logging: console.log` により全 SQL がログに出力。`INSERT INTO customers ... password_hash='$2b$10$...'` のように**ハッシュ済みパスワードが pm2 ログファイルに平文で蓄積**される。ログイン時の email も同様。

加えて `NODE_ENV` と無関係に Stripe 例外の生メッセージを常時返す箇所が 3 件ある: `src/controllers/orderController.js:589`、`src/controllers/stripeConnectController.js:67,127`。

**修正**: `.env` を `NODE_ENV=production` に変更して `pm2 restart` (`nodemon` ではなく `npm start` 経由であることを確認)。`details: error.message` の 3 箇所を削除。既存 pm2 ログのローテート・削除も行う。

### V2.4 パスワード最低長が 6 文字
`src/routes/auth.js:20,28,41` がいずれも `isLength({ min: 6 })`。一方でパスワード**変更**時は 8 文字 (`src/routes/driver.js:30`、`src/routes/restaurant.js:39`) と不整合。上限による切り詰めは無い (bcrypt の 72 バイト制限内)。
**修正**: 登録側 3 箇所を `min: 8` に統一。

### V2.5 テストアカウント (password123) が本番ツリーに存在
`seed-data.js:10` で `bcrypt.hash('password123', 10)` を全アカウント共通で使用し、`customer@test.com` / `restaurant@test.com` / `sushi@test.com` / `burger@test.com` / `driver@test.com` を作成 (`:14,49,69,89,273`)。`:322-324` はその認証情報を標準出力に表示する。`scripts/updateTestUsers.js:15-34` は既存アカウントを同じパスワードに戻す。

HTTP からは到達できないが、本番 DB がこのスクリプトで初期化されていれば `restaurant@test.com / password123` は**現在も有効なログイン情報**である。店舗アカウントは Stripe Connect アカウント作成権限を持つ (`src/routes/stripeConnect.js:12`)。

**修正**: 本番 DB で該当 5 件の存在を確認し削除。両ファイルを本番から除去する。

### V3.3 ログアウト・トークン失効の手段が無い
ログアウトエンドポイントが存在せず、`src/utils/jwt.js:10` の `expiresIn: '7d'` のみが失効手段。パスワード変更 (`src/controllers/customerController.js:99` 等) でも既存トークンは有効なままで、アカウント侵害時に締め出す方法が無い。
**修正**: 各ユーザー表に `token_version` (INT) を追加し、JWT ペイロードに含めて `src/middleware/auth.js` で照合。パスワード変更時にインクリメント。あわせて有効期限を 24 時間程度に短縮。

### V6.2 ピックアップ PIN が Math.random 生成
`src/utils/pinGenerator.js:10`。生成箇所は `src/controllers/restaurantDashboardController.js:264`。`Math.random` は予測可能で、かつ V2.2 により総当たりも防がれていない。
なお `src/app.js:129-132` の位置ぼかしにも `Math.random` を使うが、これはプライバシー加工用途でありセキュリティ統制ではないため対象外。
**修正**: `crypto.randomInt(1000, 10000)` に置換。

### V7.2 監査ログが存在しない
ログイン成否 (`src/controllers/authController.js:41,57`)、403 権限拒否 (`src/middleware/auth.js:34,44,54`)、注文ステータス変更、返金 (`src/controllers/orderController.js:363`、`src/controllers/restaurantDashboardController.js:195`)、Connect 送金 (`src/controllers/orderController.js:631,661`) のいずれも構造化された記録が無い。金銭が動く処理の追跡ができず、争いが起きた際に事実確認ができない。
**修正**: `[AUDIT]` プレフィックスで `{ts, actor_type, actor_id, action, target_id, result}` を出力する薄いヘルパーを作り、上記の各所に挿入。PIN・トークン・password_hash は出力しない。

### V13.1 CORS が全オリジン許可
`src/app.js:24` `app.use(cors())`、`src/app.js:14-19` Socket.IO `origin: '*'`。後者にはコード上に「In production, specify allowed origins」というコメントが残ったまま未対応。
**修正**: 許可オリジンを `process.env.APP_URL` に限定。クライアントは Flutter ネイティブのため CORS 許可は本来不要。

### V14.1 セキュリティヘッダが未設定
`helmet` 未導入。`/uploads/*` (`src/app.js:29`) と Stripe 復帰ページ (`src/routes/stripeConnect.js:50,81,106,137`) はブラウザで開かれる。
**修正**: `npm i helmet` + `app.use(helmet())`。

### V14.2 課金 API にレート制限が無い
上表参照。`stripe.accounts.create` (`src/controllers/stripeConnectController.js:27,92`)、`stripe.paymentIntents.create` (`src/controllers/orderController.js:561`) が認証済みなら無制限に呼べる。自己登録で店舗アカウントを作れる (追加所見 A-1) ため、攻撃コストが低い。

### V14.3 秘密情報のログ出力・破壊的スクリプト・リポジトリ衛生
- PIN の平文ログ: `src/controllers/driverController.js:417`、`src/controllers/restaurantDashboardController.js:265`
- 全 SQL ログ: `src/config/database.js:12` (`NODE_ENV=development` のため有効)
- `init-database.js:11` の `sequelize.sync({ force: true })` — 全テーブル DROP。HTTP 到達不可だが本番ツリーに存在し、誤実行で全データ消失。
- `node_modules` が **5,930 ファイル** Git 追跡されている (`.gitignore:7` に `node_modules/` の記載があるが追跡開始後のため無効)。依存の改ざんが差分に埋もれ、CI の依存脆弱性スキャンも当てにくい。
- `.claude/settings.local.json`、`food_hub/.claude/settings.local.json`、`food_hub/android/app/.claude/settings.local.json` の 3 件が追跡されている。

---

## 決済ロジックの追加所見 (ASVS 番号外・本案件固有)

決済は本案件の中核であり、チェックリストの定型項目に収まらない欠陥を個別に記録する。**P-1 と P-2 は金銭的損失に直結する。**

### P-1【重大】メニューオプション価格がクライアント制御で、支払額を任意に操作できる
`src/controllers/orderController.js:104-113`:
```js
let itemTotal = parseFloat(menuItem.price) * item.quantity;   // :104 商品本体は DB 価格 (正しい)

if (item.selected_options && item.selected_options.length > 0) {
  const optionsTotal = item.selected_options.reduce((sum, opt) => {
    return sum + (parseFloat(opt.price || 0) * item.quantity);  // :108 ← リクエストボディの値をそのまま加算
  }, 0);
  itemTotal += optionsTotal;
}
subtotal += itemTotal;                                          // :113
```
オプション価格の正は `MenuItemOption.additional_price` (`src/models/MenuItemOption.js`、書き込みは `src/controllers/restaurantMenuController.js:75`) だが、注文作成時に**DB を一切参照せず** `opt.price` というリクエスト側のフィールドを信用している。`menu_item_id` の店舗一致検証 (`:89`) や在庫確認 (`:96`) は行われているのに、価格だけが素通りする。

この `subtotal` が `:133-139` を経て `total` となり、`:562` で `stripe.paymentIntents.create({ amount: Math.round(order.total) })` の請求額そのものになる。

**攻撃例**: `POST /api/orders` に `items: [{ menu_item_id: 1, quantity: 1, selected_options: [{ price: -2000 }] }]` を送ると `subtotal` が 2000 円減額される。負値を大きくすれば `total` を数円〜0 円にでき、Stripe には最小課金額未満としてエラーになるか、正の極小額で決済が成立する。一方 `restaurant_payout` (`:145`) も同じ `subtotal` から算出されるため店舗への支払も連動して減る。逆に正の巨大値を入れれば他人の注文額を膨らませることはできない (自分の注文のみ) が、`platform_revenue` の会計が破綻する。

**修正**: `selected_options` は `menu_item_option_id` の配列のみを受け取り、サーバー側で
```js
const opts = await MenuItemOption.findAll({
  where: { id: item.selected_option_ids, menu_item_id: item.menu_item_id }
});
if (opts.length !== item.selected_option_ids.length) return res.status(400)...;
const optionsTotal = opts.reduce((s, o) => s + parseFloat(o.additional_price), 0) * item.quantity;
```
と DB 値から再計算する。`quantity` にも `isInt({ min: 1, max: 99 })` の検証を追加すること (現在 `src/routes/orders.js:23` の `createOrderValidation` に数量の範囲検証が無く、負数・小数が通る)。

### P-2【重大】支払いの成否を検証せずに調理・配達・送金が進む
`Order` モデル (`src/models/Order.js:5-153`) に **`payment_status` に相当するカラムが存在しない**。保持しているのは `stripe_payment_id` (`:84`) のみで、これは `src/controllers/orderController.js:576` で **Payment Intent を「作成した」時点**で書き込まれる。支払完了を意味しない。

そして `payment_intent.succeeded` を受ける Webhook が実装されていない。`src/controllers/stripeConnectController.js:135-181` の Webhook は `account.updated` のみを処理する (`:146`)。

結果、以下が支払い未完了のまま進行する:
- `src/controllers/restaurantDashboardController.js:113-144` `acceptOrder` — 支払確認なしで店舗が調理開始。
- `src/controllers/driverController.js:143-211` `updateDeliveryStatus` — 配達完了。
- `src/controllers/orderController.js:597-695` `processOrderPayouts` — **プラットフォーム残高から店舗・配達員へ実際に送金**。ガードは `:613` の `if (!order.stripe_payment_id) throw` のみで、これは「Payment Intent を作った」ことしか保証しない。

**攻撃例**: 顧客が注文 → `POST /api/orders/:id/create-payment-intent` を呼ぶだけでカード決済を完了させない → 店舗が受注・調理 → 配達完了 → `processOrderPayouts` が発火し、入金されていない注文に対して店舗へ `restaurant_payout`、配達員へ `driver_payout` がプラットフォーム負担で送金される。テスト鍵運用のうちは損害が出ないが、本番鍵に切り替えた瞬間に実損になる。

**修正**:
1. `orders` に `payment_status ENUM('unpaid','paid','refunded') DEFAULT 'unpaid'` を追加。
2. `payment_intent.succeeded` / `payment_intent.payment_failed` を処理する Webhook を追加し、`metadata.order_id` (`src/controllers/orderController.js:567` で既に付与済み) から注文を引いて `payment_status` を更新。
3. `acceptOrder` の冒頭で `payment_method === 'card' && payment_status !== 'paid'` を拒否。
4. `processOrderPayouts` の冒頭で同様に検証。あわせて `stripe.paymentIntents.retrieve` で `status === 'succeeded'` を再確認する二重防御を入れる。

### P-3 送金・決済に冪等キーが無く、二重送金の余地がある
`src/controllers/orderController.js:631-643,661-672` の `stripe.transfers.create` と `:561-573` の `paymentIntents.create` に `idempotencyKey` が指定されていない。

二重実行の防止は `:608` の `if (order.payout_completed) return` フラグのみだが、
- チェック (`:608`) から更新 (`:686`) までがトランザクション外・行ロック無しのため、`PATCH /api/driver/orders/:id/status` を同時に 2 本投げると両方がチェックを通過しうる。
- 店舗送金 (`:631`) の後・配達員送金 (`:661`) で例外が出ると `payout_completed` は false のまま。`src/controllers/driverController.js:207-210` は例外を握り潰すだけなので、手動再実行や再試行で**店舗への送金が再度実行される** (`stripe_restaurant_transfer_id` が既に入っているかを確認していない)。

**修正**: `transfers.create` の第 2 引数に `{ idempotencyKey: \`payout-${order.id}-restaurant\` }` / `\`payout-${order.id}-driver\`` を渡す。`processOrderPayouts` 全体を `SELECT ... FOR UPDATE` を伴うトランザクションで囲む。各送金前に `stripe_restaurant_transfer_id` / `stripe_driver_transfer_id` の有無を確認する。

### P-4 Webhook 署名検証は実装されているが、raw body が渡らず常に失敗する
`src/controllers/stripeConnectController.js:137-142` は `stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_CONNECT_WEBHOOK_SECRET)` を正しく呼んでおり、署名検証自体は必須で実装されている (**この点は適合**)。ルート側でも `express.raw({ type: 'application/json' })` を指定している (`src/routes/stripeConnect.js:43`)。

しかし `src/app.js:25` の `app.use(express.json())` が**全ルートより前にグローバル適用**されており、`/api/stripe` ルータのマウントは `src/app.js:68` と後になる。Stripe は `Content-Type: application/json` で送るため、`express.json()` が先にボディを消費して `req.body` をパース済みオブジェクトにし、後段の `express.raw` は `req._body` が立っているためスキップされる。`constructEvent` は Buffer/string 以外を受け取ると例外を投げるため、**Webhook は常に 400 を返す**。

セキュリティ上は fail-closed (検証を通らない=処理しない) であり脆弱性ではないが、機能欠陥である。現状 Stripe Connect の状態は `getAccountStatus` (`src/controllers/stripeConnectController.js:207`) が API を直接ポーリングすることで代替されているため表面化していない。P-2 で `payment_intent.succeeded` Webhook を追加する際、この順序を直さないと新しい Webhook も同様に機能しない。

**修正**: `src/app.js` で Webhook パスのみ raw を先に適用する。
```js
app.use('/api/stripe/webhook', express.raw({ type: 'application/json' }));
app.use(express.json());   // ← その後にグローバル JSON
```
または `express.json({ verify: (req, res, buf) => { req.rawBody = buf; } })` として `constructEvent(req.rawBody, ...)` を使う。

### P-5 クーポンがサーバー側で適用されておらず、使用実績も記録されない
`src/controllers/couponController.js:6-123` の `validateCoupon` は割引額を計算して返すだけで、`src/controllers/orderController.js:184` は `discount: 0` をハードコードしている。`recordUsage` (`src/controllers/couponController.js:196-208`) はどこからも呼ばれていない。

金銭的リスクは無い (常に割引 0 = 満額請求) が、クライアントが割引後価格を表示している場合、表示額と請求額が食い違う。また `validateCoupon` の `subtotal` (`:17`) はクライアント送信値で、最低注文金額判定 (`:50`) がクライアント制御になっている。将来クーポンを実装する際は、注文作成時にサーバー側で `subtotal` を再計算してから割引を適用し、同一トランザクション内で `recordUsage` を呼ぶこと (`per_user_limit` の判定 `:71-82` と使用記録が別トランザクションだと競合で上限を超過できる)。

---

## その他の追加所見

### A-1 店舗・配達員が自己登録で即時承認される (承認フローが存在しない)
`src/controllers/authController.js:186` (店舗) と `:255` (配達員) が登録時に `is_approved: true` をハードコードしている。レスポンスの文言は「Pending approval」(`:207,270`) だが実際には承認待ちにならない。管理者ロール・管理画面も存在しない (V4.5)。

誰でも `POST /api/auth/register/restaurant` で店舗になり、Stripe Connect アカウントを作成 (`src/routes/stripeConnect.js:12`) して送金先として登録できる。実際の配信対象になるには `stripe_payouts_enabled` が必要 (`src/controllers/restaurantController.js:19`、`src/controllers/restaurantDashboardController.js:120`) なため、Stripe の本人確認が事実上の唯一の関門になっている。

**修正**: `is_approved: false` を既定にし、承認用の管理エンドポイント (管理者ロール付き) を追加する。少なくとも受託範囲外なら、この仕様であることを納品時に書面で明示すること。

### A-2 公開エンドポイントが店舗の内部情報を返す
`src/controllers/restaurantController.js:65-79` `GET /api/restaurants/:id` (認証不要、`src/routes/restaurants.js:19`) は `password_hash` のみを除外して `Restaurant` 全カラムを返す。含まれるのは `email` (`src/models/Restaurant.js:10`)、`phone` (`:34`)、`stripe_account_id` (`:90`)、`stripe_charges_enabled` (`:98`)、`commission_rate` (`:106`) など。

`commission_rate` は店舗ごとの手数料率という商業的機密で、競合店舗や店舗自身が他店の条件を閲覧できる。`stripe_account_id` (`acct_...`) の外部露出も避けるべき。一覧側 `:36-45` も同様。

**修正**: 公開レスポンスを `attributes: ['id','name','description','category','address','latitude','longitude','cover_image_url','logo_url','rating','total_reviews','min_order_amount','delivery_fee','delivery_time_minutes','is_open']` のホワイトリストに変更する。

### A-3 未使用の Google Maps API キーが .env に残置
`.env:27` `GOOGLE_MAPS_API_KEY=AIzaSy...` は**バックエンド・Flutter アプリのいずれからも参照されていない** (`src/` および `food_hub/` を全走査、`AIzaSy` の出現ゼロ、`GOOGLE_MAPS` の参照ゼロ)。地図は OpenStreetMap タイル (`food_hub/lib/features/customer/widgets/order_tracking_map.dart:121` ほか) と OSRM (`food_hub/lib/features/driver/services/routing_service.dart:8`) で実装されている。

キーに HTTP リファラ/IP 制限が掛かっていない場合、漏洩時に第三者が課金を発生させられる。使っていない以上、保持する理由が無い。

**修正**: Google Cloud Console で当該キーを削除 (または無効化) し、`.env:26-27` の 2 行を削除する。

### A-4 顧客が自注文のピックアップ PIN を取得できる
`GET /api/orders/:id` (`src/controllers/orderController.js:285-318`) は注文レコードをそのまま返し、`Order.prototype.toJSON` (`src/models/Order.js:161-174`) は小数変換のみで `pickup_pin` (`src/models/Order.js:144`) を除外しない。PIN は本来「店舗 → 配達員」の受け渡し確認用であり、顧客に見せる必要が無い。V6.2・V2.2 と併せると、ピックアップ認証は多方面から回避可能な状態。
**修正**: `toJSON` で `pickup_pin` / `pin_verified_at` を削除し、店舗ダッシュボード側でのみ明示的に返す。

### A-5 クライアント側の JWT 保管 (参考・バックエンド範囲外)
`food_hub/lib/core/storage/secure_storage.dart:9-21` はファイル名に反して `SharedPreferences` を使用しており、`flutter_secure_storage` (Android Keystore / iOS Keychain) ではない。root/jailbreak 済み端末やバックアップ経由でトークンを取り出せる。V3.3 (失効手段が無い) と組み合わさると影響が長期化する。バックエンドの受託範囲外だが、クライアント側の改修候補として記録する。

---

## ? 要手動確認

### V9.1 HTTPS 強制・HSTS (nginx 設定)
アプリ側は全通信 HTTPS で cleartext 許可設定も無いことをコードで確認済みだが、TLS 終端は `133-117-77-23.nip.io` のホスト nginx にあり本リポジトリの外。

**確認方法** (サーバー上):
```bash
nginx -T | grep -nE "listen |server_name |return 301|proxy_pass|Strict-Transport-Security"
curl -sI http://133-117-77-23.nip.io/health   # 301/308 で https に飛ぶか
curl -sI https://133-117-77-23.nip.io/health  # Strict-Transport-Security の有無
```
80 → 443 のリダイレクトと `Strict-Transport-Security: max-age=31536000; includeSubDomains` が無ければ nginx 設定に追加すること。あわせて `/api/stripe/webhook/connect` が外部の Stripe から到達可能かも確認する (P-4 の修正後に Stripe ダッシュボードの Webhook ログで検証)。

---

## 付録 A: 全ルート一覧 (V4.1 検査)

`src/app.js:57-69` のマウントポイントを展開した全 74 エンドポイント。「認証」列の `auth` は `authMiddleware` (`src/middleware/auth.js:7`)、`isCustomer`/`isRestaurant`/`isDriver` は同ファイル `:32,42,52`。

### 認証 (`src/routes/auth.js`) — mount `/api/auth` (`src/app.js:57`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 1 | POST | /api/auth/login | なし | 公開 | auth.js:54 |
| 2 | POST | /api/auth/register/customer | なし | 公開 | auth.js:61 |
| 3 | POST | /api/auth/register/restaurant | なし | 公開 | auth.js:72 |
| 4 | POST | /api/auth/register/driver | なし | 公開 | auth.js:83 |
| 5 | GET | /api/auth/me | auth | 全ロール | auth.js:94 |

※ 1〜4 は仕様上公開が正しい。ただし V2.2 (レート制限なし)、V2.4 (最低 6 文字)、A-1 (3・4 が即時承認) の指摘対象。

### レストラン公開情報 (`src/routes/restaurants.js`) — mount `/api/restaurants` (`src/app.js:58`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 6 | GET | /api/restaurants | なし | 公開 | restaurants.js:12 |
| 7 | GET | /api/restaurants/:id | なし | 公開 | restaurants.js:19 |
| 8 | GET | /api/restaurants/:id/menu | なし | 公開 | restaurants.js:27 |

※ 参照系のみ。ただし 6・7 は A-2 (内部情報の露出) の指摘対象。

### メニュー品目 (`src/routes/menuItems.js`) — mount `/api/menu-items` (`src/app.js:59`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 9 | GET | /api/menu-items/:id | なし | 公開 | menuItems.js:11 |

### 注文 — 顧客 (`src/routes/orders.js`) — mount `/api/orders` (`src/app.js:60`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 10 | POST | /api/orders | auth | isCustomer | orders.js:23 |
| 11 | GET | /api/orders | auth | isCustomer | orders.js:37 |
| 12 | GET | /api/orders/:id | auth | isCustomer | orders.js:44 |
| 13 | PATCH | /api/orders/:id/cancel | auth | isCustomer | orders.js:51 |
| 14 | GET | /api/orders/:id/tracking | auth | isCustomer | orders.js:58 |
| 15 | POST | /api/orders/:id/create-payment-intent | auth | isCustomer | orders.js:65 |

※ 10 は P-1、12 は A-4 の指摘対象。

### 住所・お気に入り (`src/routes/addresses.js`) — mount `/api` (`src/app.js:61`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 16 | GET | /api/customers/:customerId/addresses | auth | isCustomer | addresses.js:21 |
| 17 | POST | /api/customers/:customerId/addresses | auth | isCustomer | addresses.js:33 |
| 18 | PUT | /api/addresses/:id | auth | isCustomer | addresses.js:46 |
| 19 | DELETE | /api/addresses/:id | auth | isCustomer | addresses.js:59 |
| 20 | PATCH | /api/addresses/:id/default | auth | isCustomer | addresses.js:71 |
| 21 | GET | /api/customers/:customerId/favorites | auth | isCustomer | addresses.js:83 |

### お気に入り (`src/routes/favorites.js`) — mount `/api/favorites` (`src/app.js:62`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 22 | GET | /api/favorites | auth | isCustomer | favorites.js:18 |
| 23 | POST | /api/favorites | auth | isCustomer | favorites.js:30 |
| 24 | DELETE | /api/favorites/:id | auth | isCustomer | favorites.js:43 |

### レビュー (`src/routes/reviews.js`) — mount `/api/reviews` (`src/app.js:63`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 25 | GET | /api/reviews/restaurant/:restaurantId | なし | 公開 | reviews.js:39 |
| 26 | POST | /api/reviews | auth | isCustomer | reviews.js:43 |
| 27 | GET | /api/reviews/my | auth | isCustomer | reviews.js:46 |
| 28 | GET | /api/reviews/can-review/:orderId | auth | isCustomer | reviews.js:49 |
| 29 | PUT | /api/reviews/:id | auth | isCustomer | reviews.js:52 |
| 30 | DELETE | /api/reviews/:id | auth | isCustomer | reviews.js:55 |

※ 25 は公開だが顧客名をマスク処理済み (`src/controllers/reviewController.js:27-36`)。

### クーポン (`src/routes/coupons.js`) — mount `/api/coupons` (`src/app.js:64`)

`router.use(authMiddleware, isCustomer)` を `coupons.js:22` で一括適用。

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 31 | POST | /api/coupons/validate | auth | isCustomer | coupons.js:25 |
| 32 | GET | /api/coupons/available | auth | isCustomer | coupons.js:28 |

※ P-5 の指摘対象。

### 顧客プロフィール (`src/routes/customers.js`) — mount `/api/customers` (`src/app.js:65`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 33 | GET | /api/customers/profile | auth | isCustomer | customers.js:38 |
| 34 | PUT | /api/customers/profile | auth | isCustomer | customers.js:50 |
| 35 | PATCH | /api/customers/password | auth | isCustomer | customers.js:63 |

### 店舗ダッシュボード (`src/routes/restaurant.js`) — mount `/api/restaurant` (`src/app.js:66`)

`router.use(authMiddleware)` (`restaurant.js:11`) + `router.use(isRestaurant)` (`restaurant.js:12`) を全ルートに一括適用。

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 36 | GET | /api/restaurant/profile | auth | isRestaurant | restaurant.js:21 |
| 37 | PATCH | /api/restaurant/profile | auth | isRestaurant | restaurant.js:28 |
| 38 | PATCH | /api/restaurant/password | auth | isRestaurant | restaurant.js:35 |
| 39 | PATCH | /api/restaurant/address | auth | isRestaurant | restaurant.js:49 |
| 40 | GET | /api/restaurant/orders | auth | isRestaurant | restaurant.js:65 |
| 41 | GET | /api/restaurant/orders/:id | auth | isRestaurant | restaurant.js:72 |
| 42 | PATCH | /api/restaurant/orders/:id/accept | auth | isRestaurant | restaurant.js:79 |
| 43 | PATCH | /api/restaurant/orders/:id/reject | auth | isRestaurant | restaurant.js:86 |
| 44 | PATCH | /api/restaurant/orders/:id/status | auth | isRestaurant | restaurant.js:93 |
| 45 | GET | /api/restaurant/stats | auth | isRestaurant | restaurant.js:105 |
| 46 | GET | /api/restaurant/menu | auth | isRestaurant | restaurant.js:115 |
| 47 | POST | /api/restaurant/menu | auth | isRestaurant | restaurant.js:122 |
| 48 | PUT | /api/restaurant/menu/:id | auth | isRestaurant | restaurant.js:137 |
| 49 | DELETE | /api/restaurant/menu/:id | auth | isRestaurant | restaurant.js:152 |
| 50 | PATCH | /api/restaurant/menu/:id/availability | auth | isRestaurant | restaurant.js:159 |

※ 42 は P-2 (支払未検証で受注)、44 は PIN 生成箇所で V2.3/V6.2 の指摘対象。

### 配達員 (`src/routes/driver.js`) — mount `/api/driver` (`src/app.js:67`)

`router.use(authMiddleware)` (`driver.js:9`) + `router.use(isDriver)` (`driver.js:10`) を全ルートに一括適用。

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 51 | GET | /api/driver/profile | auth | isDriver | driver.js:19 |
| 52 | PATCH | /api/driver/password | auth | isDriver | driver.js:26 |
| 53 | GET | /api/driver/available-orders | auth | isDriver | driver.js:42 |
| 54 | GET | /api/driver/orders | auth | isDriver | driver.js:50 |
| 55 | POST | /api/driver/orders/:id/accept | auth | isDriver | driver.js:57 |
| 56 | PATCH | /api/driver/orders/:id/status | auth | isDriver | driver.js:64 |
| 57 | POST | /api/driver/orders/:id/verify-pin | auth | isDriver | driver.js:75 |
| 58 | PATCH | /api/driver/location | auth | isDriver | driver.js:88 |
| 59 | PATCH | /api/driver/online | auth | isDriver | driver.js:102 |
| 60 | GET | /api/driver/stats | auth | isDriver | driver.js:114 |

※ 53・55 は未割当注文を全配達員に開放する設計 (マーケットプレイス仕様として意図的)。57 は V2.2/V6.2、56 は P-2/P-3 の指摘対象。**58 は HTTP 経由では `req.user.id` を使い安全 (`src/controllers/driverController.js:234`) だが、同等の機能を持つ Socket.IO 経路が無認証** (V4.1)。

### Stripe Connect (`src/routes/stripeConnect.js`) — mount `/api/stripe` (`src/app.js:68`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 61 | POST | /api/stripe/connect/restaurant | auth | isRestaurant | stripeConnect.js:12 |
| 62 | POST | /api/stripe/connect/driver | auth | isDriver | stripeConnect.js:24 |
| 63 | GET | /api/stripe/status | auth | **ロール検査なし** | stripeConnect.js:36 |
| 64 | POST | /api/stripe/webhook/connect | なし (署名検証) | 公開 | stripeConnect.js:43 |
| 65 | GET | /api/stripe/restaurant/return | なし | 公開 (静的 HTML) | stripeConnect.js:50 |
| 66 | GET | /api/stripe/restaurant/refresh | なし | 公開 (静的 HTML) | stripeConnect.js:81 |
| 67 | GET | /api/stripe/driver/return | なし | 公開 (静的 HTML) | stripeConnect.js:106 |
| 68 | GET | /api/stripe/driver/refresh | なし | 公開 (静的 HTML) | stripeConnect.js:137 |

- **63**: ロールミドルウェアは無いが、ハンドラ (`src/controllers/stripeConnectController.js:190-198`) が署名済み JWT の `user_type` で分岐し `req.user.id` のレコードのみを返すため所有者越境は起きない。`customer` の場合は `user` が undefined となり 404 (`:200`)。**問題なし**。
- **64**: 認証ミドルウェアの代わりに `stripe.webhooks.constructEvent` による署名検証を実施 (`src/controllers/stripeConnectController.js:138-142`)。**署名検証は必須実装されており適合**。ただし raw body が届かず常に失敗する不具合あり (P-4)。処理内容は `account.updated` による Connect 状態の更新のみで、`account.id` からレコードを引く (`:150-152,163-165`) ため所有者越境なし。
- **65〜68**: `res.send` による固定 HTML。ユーザー入力の埋め込み・DB アクセス・状態変更のいずれも無し (V5.2 で確認済み)。

### アップロード (`src/routes/upload.js`) — mount `/api/upload` (`src/app.js:69`)

`router.use(authMiddleware)` (`upload.js:9`) + `router.use(isRestaurant)` (`upload.js:10`) を一括適用。

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 69 | POST | /api/upload/menu-images | auth | isRestaurant | upload.js:17 |
| 70 | POST | /api/upload/restaurant-images | auth | isRestaurant | upload.js:31 |
| 71 | DELETE | /api/upload/image | auth | isRestaurant | upload.js:45 |

※ **71 は所有者チェックが無く V4.2 の × 対象**。

### アプリ直下 (`src/app.js`)

| # | Method | Path | 認証 | ロール | 定義 |
|---|---|---|---|---|---|
| 72 | GET | /health | なし | 公開 | app.js:32 |
| 73 | GET | /api | なし | 公開 | app.js:41 |
| 74 | GET | /uploads/* (静的配信) | なし | 公開 | app.js:29 |

※ 72・73 は固定文字列のみを返し情報漏洩なし。74 はメニュー画像の公開配信で仕様通り (V5.5 参照)。

### Socket.IO イベント (`src/app.js:94-159`) — nginx が `/socket.io/` をプロキシするため外部到達可能

| # | Event | 認証 | 状態変更 | 定義 | 判定 |
|---|---|---|---|---|---|
| S1 | connection | **なし** (`io.use` 未設定) | — | app.js:94 | × |
| S2 | driver:register | **なし** (`token` を受領するが検証せず) | activeDrivers / room join | app.js:98 | × |
| S3 | driver:location-update | **なし** (`driverId` はクライアント値) | `Driver.update` (DB 書込) + 全体ブロードキャスト | app.js:110 | × |
| S4 | disconnect | — | activeDrivers から削除 | app.js:152 | — |

**S3 が V4.1 / V4.2 を × とした直接の根拠。** 詳細は「× 項目の詳細」を参照。

---

## 付録 B: 所有者チェック (IDOR) の確認結果

`:id` を受け取る全エンドポイントについて、`where` 句に所有者条件が入っているかを個別に確認した。

| エンドポイント | 所有者条件 | 根拠 | 判定 |
|---|---|---|---|
| GET /api/orders/:id | `{ id, customer_id }` | orderController.js:291 | ○ |
| PATCH /api/orders/:id/cancel | `{ id, customer_id }` | orderController.js:335 | ○ |
| GET /api/orders/:id/tracking | `{ id, customer_id }` | orderController.js:402 | ○ |
| POST /api/orders/:id/create-payment-intent | `{ id, customer_id }` | orderController.js:537 | ○ |
| GET /api/customers/:customerId/addresses | `parseInt(customerId) !== req.user.id` で 403 | addressController.js:14-16 | ○ |
| POST /api/customers/:customerId/addresses | 同上 | addressController.js:50-52 | ○ |
| PUT /api/addresses/:id | `{ id, customer_id }` | addressController.js:108 | ○ |
| DELETE /api/addresses/:id | `{ id, customer_id }` | addressController.js:153 | ○ |
| PATCH /api/addresses/:id/default | `{ id, customer_id }` | addressController.js:181 | ○ |
| DELETE /api/favorites/:id | `{ id, customer_id }` | favoriteController.js:104 | ○ |
| PUT /api/reviews/:id | `{ id, customer_id: customerId }` | reviewController.js:204-207 | ○ |
| DELETE /api/reviews/:id | `{ id, customer_id: customerId }` | reviewController.js:243-246 | ○ |
| POST /api/reviews (order_id 検証) | `{ id: order_id, customer_id }` + `status==='delivered'` + 重複チェック | reviewController.js:88-120 | ○ |
| GET /api/reviews/can-review/:orderId | `{ id: orderId, customer_id }` | reviewController.js:278-281 | ○ |
| GET /api/restaurant/orders/:id | `{ id, restaurant_id }` | restaurantDashboardController.js:74 | ○ |
| PATCH /api/restaurant/orders/:id/accept | `{ id, restaurant_id }` | restaurantDashboardController.js:128 | ○ |
| PATCH /api/restaurant/orders/:id/reject | `{ id, restaurant_id }` | restaurantDashboardController.js:167 | ○ |
| PATCH /api/restaurant/orders/:id/status | `{ id, restaurant_id }` | restaurantDashboardController.js:239 | ○ |
| PUT /api/restaurant/menu/:id | `{ id, restaurant_id }` | restaurantMenuController.js:115 | ○ |
| DELETE /api/restaurant/menu/:id | `{ id, restaurant_id }` | restaurantMenuController.js:153 | ○ |
| PATCH /api/restaurant/menu/:id/availability | `{ id, restaurant_id }` | restaurantMenuController.js:189 | ○ |
| POST /api/driver/orders/:id/accept | `{ id, status:'ready', driver_id: null }` + `LOCK.UPDATE` | driverController.js:107-111 | ○ |
| PATCH /api/driver/orders/:id/status | `{ id, driver_id }` + 状態遷移検証 | driverController.js:154-173 | ○ |
| POST /api/driver/orders/:id/verify-pin | `{ id, driver_id, status:'ready' }` | driverController.js:407-409 | ○ |
| POST /api/orders (配送先住所) | `{ id: delivery_address_id, customer_id }` | orderController.js:75-77 | ○ |
| POST /api/orders (メニュー品目) | `menuItem.restaurant_id !== restaurant_id` で 400 | orderController.js:89 | ○ |
| GET /api/stripe/status | JWT の `user_type` で分岐 + `findByPk(req.user.id)` | stripeConnectController.js:190-198 | ○ |
| **DELETE /api/upload/image** | **なし** | uploadController.js:62-84 | **×** |
| **Socket driver:location-update** | **なし** | app.js:110-121 | **×** |

プロフィール系 (`/api/customers/profile`、`/api/restaurant/profile`、`/api/driver/profile` とパスワード変更) はいずれも `req.user.id` のみを使用し、リクエストから ID を受け取らないため構造的に IDOR が発生しない。

---

## 次のアクション (優先度順)

1. **V3.2** — `JWT_SECRET` を乱数に差し替えて再起動 (5 分。これを実施しない限り他の対策は無意味)
2. **P-1** — オプション価格をサーバー側で DB から再計算 + `quantity` の範囲検証
3. **P-2** — `payment_status` 追加 + `payment_intent.succeeded` Webhook + 受注/送金前の検証 (**P-4 の raw body 修正が前提**)
4. **V2.5 / V7.1** — 本番のテストアカウント削除、`NODE_ENV=production` 化 + pm2 再起動 + 既存ログの削除
5. **V4.1** — Socket.IO の `io.use` 認証追加、`io.emit` をルーム限定に変更
6. **V4.2** — 画像削除の所有者チェック
7. **P-3** — 送金の冪等キー + トランザクション化
8. **V2.2 / V6.2** — レート制限導入 + PIN を `crypto.randomInt` 化
9. **V13.1 / V14.1** — CORS 限定、helmet 導入
10. **V2.4 / V3.3 / V7.2 / V14.3 / A-2 / A-3 / A-4** — パスワード長統一、トークン失効、監査ログ、ログ衛生・`node_modules` の追跡解除、公開レスポンスのホワイトリスト化、未使用 Maps キー削除、PIN の非公開化
11. **V9.1** — nginx の HTTPS リダイレクト・HSTS を確認 (`?` の解消)

修正後は本チェックリストを再実行し、判定を更新すること (SKILL.md 手順 6: 修正は別パスで行い、同一ターンで自己承認しない)。

---

## 修正実施 (2026-08-29)

- 実施者: Claude Code (fix パス) / レビュー: (未記入)
- 対象: `foodhub-backend/` のみ。Flutter アプリ `food_hub/` と `node_modules/` は変更していない。
- 検証: 変更した全 JS に `node --check` (19 ファイル OK)。加えてスクラッチ領域に helmet / express-rate-limit / socket.io-client を入れ、`NODE_PATH` 経由で実際にサーバーを起動して 14 項目のスモークテストを実行 (全 PASS)。プロジェクトの `node_modules/` には一切書き込んでいない。

### 修正した項目

| # | 項目 | 対応内容 | 変更ファイル |
|---|---|---|---|
| V3.2 | JWT 署名鍵 | 起動時に `JWT_SECRET` を検証し、未設定 / 32 文字未満 / 既知のプレースホルダ (`.env.example` の値を実行時に読んで比較 + ハードコードした既知値) のいずれかなら **例外を投げてプロセスを起動させない**。あわせて署名・検証で `HS256` を明示 | `src/utils/jwt.js`、`.env.example` (新規) |
| V2.2 | レート制限 / ロックアウト | `express-rate-limit` を導入。login・register×3 に IP あたり 15 分 10 回。加えて**アカウント単位のロックアウト** (同一 `user_type`+email で 5 回連続失敗 → 15 分ロック、メモリ内)。`verify-pin` は配達員 ID 単位で 10 分 5 回。`app.set('trust proxy', 1)` を設定 | `src/middleware/rateLimit.js` (新規)、`src/routes/auth.js`、`src/routes/driver.js`、`src/app.js`、`src/controllers/authController.js` |
| V2.3 | 認証情報のログ出力 | ピックアップ PIN の平文ログ 2 箇所を削除し、代わりに PIN を含まない監査ログに置換。Socket.IO の位置座標ログも削除 | `src/controllers/driverController.js`、`src/controllers/restaurantDashboardController.js`、`src/app.js` |
| V6.2 | PIN の乱数 | `Math.random` → `crypto.randomInt(1000, 10000)` | `src/utils/pinGenerator.js` |
| V4.2 | 画像削除の IDOR | `DELETE /api/upload/image` に所有者チェックを追加。自店舗の `MenuItem.image_url`、または自店舗の `cover_image_url` / `logo_url` に一致する場合のみ削除する。不一致は (存在有無を漏らさないため) 404。パスは `path.basename` で正規化したうえで `path.resolve` 後に `uploads/` 配下であることを再確認 | `src/controllers/uploadController.js` |
| V3.3 | ログアウト / トークン失効 | 署名時に `jti` を付与し、`POST /api/auth/logout` で失効リストに登録。認証ミドルウェアと Socket.IO ハンドシェイクの両方で照合する | `src/utils/jwt.js`、`src/utils/tokenDenylist.js` (新規)、`src/middleware/auth.js`、`src/controllers/authController.js`、`src/routes/auth.js`、`src/app.js` |
| V2.4 | パスワード最低長 | 登録 3 経路を `min: 6` → `min: 8` に統一 (パスワード変更側と一致) | `src/routes/auth.js` |
| V2.5 | テストアカウント | `seed-data.js` の固定 `password123` を廃止し、実行ごとのランダムパスワード (base64url 24 文字) を生成してその実行時に 1 度だけ表示。`NODE_ENV=production` では実行を拒否 (`ALLOW_SEED_IN_PRODUCTION=yes` の明示指定がない限り)。同じ問題があった `scripts/updateTestUsers.js` にも同じ対処を適用 | `seed-data.js`、`scripts/updateTestUsers.js` |
| V7.1 | エラー詳細の露出 | グローバルエラーハンドラは `NODE_ENV=development` 以外で `message` を返さない (サーバー側 `console.error` は維持)。Stripe 例外の生メッセージを返していた `details: error.message` 3 箇所を削除 | `src/app.js`、`src/controllers/orderController.js`、`src/controllers/stripeConnectController.js` |
| V7.2 | 監査ログ | `utils/audit.js` を追加し `[AUDIT] {JSON}` の 1 行 1 レコードで出力。対象: ログイン成功/失敗 (IP + マスク済みメール + 失敗理由)、ロックアウト、403 権限拒否、失効トークンの使用、注文ステータス変更 (店舗・配達員)、PIN 生成/照合の成否、返金・キャンセル、Payment Intent 作成、店舗/配達員への送金、Stripe Webhook 受信と署名検証失敗、Socket.IO の接続/拒否/切断。PIN・トークン・`password_hash` は出力しない | `src/utils/audit.js` (新規) ほか各コントローラ |
| V13.1 | CORS | `ALLOWED_ORIGINS` (カンマ区切り、未設定なら `APP_URL`) の許可リスト方式に変更、`credentials: false`。Socket.IO にも同じリストを適用。`Origin` ヘッダの無いリクエスト (Flutter ネイティブ・Stripe Webhook) は許可、ブラウザ由来の未登録オリジンは 403 | `src/app.js` |
| V4.1 / V4.2 (S1-S3) | Socket.IO | `io.use` でハンドシェイク時に JWT を検証 (`socket.handshake.auth.token`、互換のため `Authorization` ヘッダも受理)。失効済みトークンも拒否。`driver:register` / `driver:location-update` はクライアント送信の `driverId` を無視し **JWT の ID のみ**を使用し、配達員以外は拒否。ブロードキャストは `io.emit` (全接続) をやめ、`driver-<id>` と担当中注文の `order-<id>` ルーム限定に変更。顧客が自注文を追跡するための `customer:track-order` / `customer:untrack-order` を追加 (所有者確認あり) | `src/app.js` |
| V14.1 | セキュリティヘッダ | `helmet({ contentSecurityPolicy: false })` を適用 (CSP を切っている理由はコード内に明記)。`/uploads` のみ `Cross-Origin-Resource-Policy: cross-origin` を付与し画像配信が壊れないようにした | `src/app.js` |
| V14.2 | 課金 API のレート制限 | `POST /api/stripe/connect/restaurant`、`/connect/driver`、`POST /api/orders/:id/create-payment-intent` にユーザー単位 1 分 10 回の制限 | `src/routes/stripeConnect.js`、`src/routes/orders.js`、`src/middleware/rateLimit.js` |

### 追加した依存 (バージョン固定・`npm install` は未実行)

```
"express-rate-limit": "8.6.2"
"helmet": "8.3.0"
```

### 動作確認の結果

サーバーを実際に起動して確認 (14/14 PASS):

- プレースホルダのままの `JWT_SECRET` では**起動を拒否**することを確認 (未設定 / 6 文字 / 旧プレースホルダ / `.env.example` の値の 4 パターンすべて拒否、ランダム値のみ起動可)
- helmet ヘッダ: `X-Content-Type-Options: nosniff` / `X-Frame-Options: SAMEORIGIN` / `Referrer-Policy: no-referrer` を付与、CSP は意図通り未設定
- CORS: 許可オリジンは 200、未許可オリジンは 403、`Origin` 無しは 200
- レート制限: `POST /api/auth/login` の 11 回目以降が 429
- アカウントロックアウト: 5 回連続失敗で 429、別アカウントは無影響、メールの大文字小文字では回避不可、成功でリセット
- ログアウト: `jti` 失効後は同じトークンが 401 (`Token has been revoked`)
- Socket.IO: トークン無し / 不正トークンは接続拒否、正当な配達員トークンは接続・登録成功、**顧客トークンで `driver:register` / 他人の `driver:location-update` を送っても拒否**される
- PIN: `crypto.randomInt` で 20,000 件生成し全件が 1000-9999 の 4 桁

### 運用側で必要な作業

1. `cd /root/uber/foodhub-backend && npm install` (`express-rate-limit` と `helmet` の取得。※ 本スナップショットの `node_modules` には `multer` も欠けていたため、この install は必須)
2. `.env` に `ALLOWED_ORIGINS=https://133-117-77-23.nip.io` を追加 (未設定でも `APP_URL` にフォールバックする)
3. `pm2 restart` — **`JWT_SECRET` がプレースホルダ/32 文字未満のままだと起動しない**。起動失敗時は `pm2 logs` に日本語の理由と生成コマンドが出る
4. 既存の pm2 ログには PIN・SQL・ハッシュ済みパスワードが残っているため、ローテートまたは削除する
5. 本番 DB のテストアカウント (`customer@test.com` / `restaurant@test.com` / `sushi@test.com` / `burger@test.com` / `driver@test.com`) の存在を確認し削除する — これはコード修正では消えない
6. リポジトリルートの `.gitignore:4` の `.env.*` により、今回追加した `foodhub-backend/.env.example` が Git の追跡対象外になっている。コミットするなら `.gitignore` に `!foodhub-backend/.env.example` を追記すること (本タスクは `foodhub-backend/` 配下のみ変更する指示だったためルートの `.gitignore` は変更していない)。なお `.env.example` が存在しなくても `src/utils/jwt.js` はハードコードした既知プレースホルダ一覧で検証を続行する

### Flutter クライアント側で必要な変更 (これを行わないとリアルタイム追跡が動かない)

Socket.IO のハンドシェイクに JWT が必須になった。**未対応のままだと接続が `unauthorized` で拒否される。**

1. `food_hub/lib/features/driver/services/driver_socket_service.dart:36-43` — `OptionBuilder` に `.setAuth({'token': authToken})` を追加する (現在の `.setExtraHeaders({'Authorization': 'Bearer $authToken'})` は WebSocket 専用トランスポートでは環境によって送られないため、`auth` を使うこと)。`_registerDriver()` / `_sendLocationUpdate()` が送っている `driverId` はサーバーが無視するので、そのままでも害はない (削除してもよい)。
2. `food_hub/lib/core/services/socket_service.dart:29-35` — 顧客側は現在トークンを一切送っていない。同様に `.setAuth({'token': <顧客のJWT>})` を追加する。
3. 同 `socket_service.dart` — 位置情報が全接続へのブロードキャストではなく注文ルーム限定になったため、追跡開始時に `socket.emit('customer:track-order', {'orderId': <注文ID>})` を送る必要がある (サーバー側で自分の注文かを検証する)。追跡終了時は `customer:untrack-order`。これを送らないと `driver:location-changed` は届かない。
4. `food_hub/lib/features/driver/services/background_location_service.dart:97-111` — HTTP 経由の位置更新はサーバー側で従来どおり `req.user.id` を使うため変更不要。
5. ログアウト時に `POST /api/auth/logout` を呼ぶとサーバー側でもトークンが失効する (任意だが推奨)。

### 今回対応していない項目

以下は本タスクの指示範囲外のため未着手。**特に P-1 / P-2 は金銭的損失に直結するため、別途対応が必要。**

- **P-1** メニューオプション価格のクライアント制御 (支払額の任意操作) — 未対応
- **P-2** 支払い成否を検証せずに調理・配達・送金が進む — 未対応
- **P-3** 送金の冪等キー・トランザクション化 — 未対応
- **P-4** Stripe Webhook に raw body が渡らず常に失敗する — 未対応
- **P-5** クーポンがサーバー側で適用されていない — 未対応
- **A-1** 店舗・配達員の自動承認 (`is_approved: true` ハードコード) — 未対応
- **A-2** 公開エンドポイントが `commission_rate` / `stripe_account_id` 等を返す — 未対応
- **A-3** 未使用の Google Maps API キーが `.env` に残置 — 未対応 (運用側で削除)
- **A-4** 顧客が自注文の `pickup_pin` を取得できる — 未対応
- **V14.3** `init-database.js` の `sync({ force: true })`、`node_modules` の Git 追跡解除 — 未対応 (`node_modules` は変更しない指示のため)
- **V9.1** nginx の HTTPS リダイレクト・HSTS 確認 — サーバー側作業のため未実施
- JWT の有効期限 7 日は変更していない (短縮 + リフレッシュトークンは別途検討)

> 失効リストとアカウントロックアウトは**いずれもプロセス内メモリ**で保持している。pm2 を cluster モードにする / インスタンスを増やす場合は Redis 等の共有ストアへ移すこと (該当コードにコメントを記載済み)。
