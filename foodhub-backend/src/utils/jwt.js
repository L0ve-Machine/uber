const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');

/** JWT 署名鍵の最低長 (ASVS V3.2)。HS256 の鍵としてこれ未満は認めない。 */
const MIN_SECRET_LENGTH = 32;

/**
 * 既知のプレースホルダ値。
 * これらが .env に入ったままだと第三者が任意のトークンを偽造できるため、
 * 起動そのものを拒否する。
 */
const KNOWN_PLACEHOLDERS = [
  'your_jwt_secret_key_change_this_in_production_12345',
  'CHANGE_ME_GENERATE_A_RANDOM_48_BYTE_SECRET',
  'your_jwt_secret',
  'secret',
  'changeme',
];

/**
 * .env.example に書かれている JWT_SECRET の値を読む。
 * サンプルからコピーしたまま値を変えていないケースを検出するために使う。
 * ファイルが無い / 読めない場合は null を返す (本番デプロイに .env.example が
 * 含まれないことがあるため、これ自体はエラーにしない)。
 * @returns {String|null}
 */
function readExamplePlaceholder() {
  try {
    const examplePath = path.join(__dirname, '../../.env.example');
    const content = fs.readFileSync(examplePath, 'utf8');
    const match = content.match(/^\s*JWT_SECRET\s*=\s*(.*)$/m);
    if (!match) return null;
    return match[1].trim().replace(/^["']|["']$/g, '');
  } catch (error) {
    return null;
  }
}

/**
 * JWT_SECRET を検証して返す。不正なら例外を投げる。
 * 起動時 (モジュール読み込み時) に 1 度実行され、問題があればプロセスを止める。
 * 「弱い鍵のまま静かに動き続ける」ことが最悪の結果なので、fail-fast にする。
 * @returns {String} 検証済みの署名鍵
 */
function assertJwtSecret() {
  const secret = process.env.JWT_SECRET;

  if (!secret || secret.trim() === '') {
    throw new Error(
      'JWT_SECRET が設定されていません。.env に 32 文字以上のランダムな値を設定してください。\n' +
        '生成例: node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'base64url\'))"'
    );
  }

  if (secret.length < MIN_SECRET_LENGTH) {
    throw new Error(
      `JWT_SECRET が短すぎます (${secret.length} 文字)。${MIN_SECRET_LENGTH} 文字以上のランダムな値を設定してください。\n` +
        '生成例: node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'base64url\'))"'
    );
  }

  const placeholders = [...KNOWN_PLACEHOLDERS];
  const examplePlaceholder = readExamplePlaceholder();
  if (examplePlaceholder) {
    placeholders.push(examplePlaceholder);
  }

  const normalized = secret.trim().toLowerCase();
  const isPlaceholder = placeholders.some(
    (p) => p && normalized === p.trim().toLowerCase()
  );

  if (isPlaceholder) {
    throw new Error(
      'JWT_SECRET がプレースホルダのままです。この値は公開されており、任意のユーザー・任意のロールへのなりすましが可能になります。\n' +
        '必ず固有のランダム値に差し替えてサーバーを再起動してください。\n' +
        '生成例: node -e "console.log(require(\'crypto\').randomBytes(48).toString(\'base64url\'))"'
    );
  }

  return secret;
}

// 起動時に 1 度だけ検証する。不正な鍵ではプロセスを起動させない (ASVS V3.2)。
const JWT_SECRET = assertJwtSecret();

/**
 * Generate JWT token
 * @param {Object} payload - Data to encode in token
 * @returns {String} JWT token
 */
const generateToken = (payload) => {
  return jwt.sign(
    {
      ...payload,
      // jti: ログアウト時にこの ID を失効リストへ登録する (ASVS V3.3)
      jti: crypto.randomUUID(),
    },
    JWT_SECRET,
    {
      algorithm: 'HS256',
      expiresIn: '7d', // Token expires in 7 days
    }
  );
};

/**
 * Verify JWT token
 * @param {String} token - JWT token to verify
 * @returns {Object} Decoded payload
 */
const verifyToken = (token) => {
  try {
    // アルゴリズムを明示し、alg 混同攻撃 (alg: none 等) の余地を残さない
    return jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
  } catch (error) {
    throw new Error('Invalid token');
  }
};

module.exports = {
  generateToken,
  verifyToken,
  assertJwtSecret,
  MIN_SECRET_LENGTH,
};
