/**
 * レート制限 / アカウントロックアウト (ASVS V2.2, V14.2)
 *
 * 前提: src/app.js で app.set('trust proxy', 1) を設定済み。
 *   ホスト nginx (133-117-77-23.nip.io) → localhost:3000 の 1 ホップ構成なので、
 *   X-Forwarded-For の最終ホップを実クライアント IP として信頼できる。
 *   ホップ数が変わった場合は必ずこの値も合わせること
 *   (過大に設定すると攻撃者が任意の IP を詐称してレート制限を回避できる)。
 */

const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const { audit, maskEmail, clientIp } = require('../utils/audit');

/**
 * ログイン・登録用: IP あたり 15 分で 10 リクエスト
 * パスワード総当たりとアカウント大量作成の両方を抑止する。
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    error: 'Too many requests',
    message: '試行回数が多すぎます。15 分ほど時間をおいてからお試しください。',
  },
  handler: (req, res, next, options) => {
    audit('ratelimit.exceeded', {
      scope: 'auth',
      path: req.originalUrl,
      ip: clientIp(req),
      result: 'blocked',
    });
    res.status(options.statusCode).json(options.message);
  },
});

/**
 * ピックアップ PIN 検証用: IP あたり 10 分で 5 リクエスト
 * 4 桁 PIN (9000 通り) の総当たりを実質不可能にする。
 */
const verifyPinLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  // 認証済みルートなので配達員 ID 単位で数える (IP を変えても回避できない)
  keyGenerator: (req) =>
    req.user?.id ? `driver-${req.user.id}` : ipKeyGenerator(req.ip),
  message: {
    error: 'Too many attempts',
    message: 'PIN の入力試行が多すぎます。しばらく待ってからお試しください。',
  },
  handler: (req, res, next, options) => {
    audit('ratelimit.exceeded', {
      scope: 'verify-pin',
      actor_type: req.user?.user_type,
      actor_id: req.user?.id,
      ip: clientIp(req),
      result: 'blocked',
    });
    res.status(options.statusCode).json(options.message);
  },
});

/**
 * Stripe 課金系エンドポイント用: ユーザーあたり 1 分で 10 リクエスト
 * stripe.accounts.create / paymentIntents.create の連打を防ぐ (ASVS V14.2)。
 */
const stripeLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) =>
    req.user?.id
      ? `${req.user.user_type}-${req.user.id}`
      : ipKeyGenerator(req.ip),
  message: {
    error: 'Too many requests',
    message: '決済関連の操作が多すぎます。少し時間をおいてからお試しください。',
  },
  handler: (req, res, next, options) => {
    audit('ratelimit.exceeded', {
      scope: 'stripe',
      path: req.originalUrl,
      actor_type: req.user?.user_type,
      actor_id: req.user?.id,
      ip: clientIp(req),
      result: 'blocked',
    });
    res.status(options.statusCode).json(options.message);
  },
});

// ==================== アカウント単位のロックアウト ====================

/**
 * IP 単位のレート制限だけでは、分散 IP から 1 アカウントを狙う攻撃を防げない。
 * そこで「アカウント (user_type + email)」単位でも失敗回数を数える。
 *
 * ⚠️ プロセス内メモリ実装。マルチプロセス化する場合は Redis に移すこと
 *    (キー: login-fail:<user_type>:<email>、INCR + EXPIRE で同等の挙動になる)。
 */
const LOCKOUT_THRESHOLD = 5; // 連続失敗がこの回数に達したらロック
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // ロック時間 15 分
const FAILURE_WINDOW_MS = 15 * 60 * 1000; // この時間内の失敗のみ数える

/** @type {Map<string, {count: number, firstFailedAt: number, lockedUntil: number}>} */
const loginFailures = new Map();

/**
 * ロックアウト判定用のキーを作る
 * email は大文字小文字の差で回避されないよう正規化する。
 */
function lockoutKey(userType, email) {
  return `${userType || 'unknown'}:${String(email || '').trim().toLowerCase()}`;
}

/**
 * 期限切れエントリを掃除する (メモリリーク防止)
 */
function purgeLoginFailures() {
  const now = Date.now();
  for (const [key, entry] of loginFailures) {
    const expired =
      entry.lockedUntil <= now && now - entry.firstFailedAt > FAILURE_WINDOW_MS;
    if (expired) {
      loginFailures.delete(key);
    }
  }
}
const purgeTimer = setInterval(purgeLoginFailures, 10 * 60 * 1000);
if (typeof purgeTimer.unref === 'function') {
  purgeTimer.unref();
}

/**
 * ログイン試行前にロック状態を確認するミドルウェア
 * ロック中は 429 を返し、パスワード照合まで到達させない。
 */
function loginLockout(req, res, next) {
  const { email, user_type } = req.body || {};
  if (!email || !user_type) {
    // バリデーションは後段の express-validator に任せる
    return next();
  }

  const entry = loginFailures.get(lockoutKey(user_type, email));
  if (entry && entry.lockedUntil > Date.now()) {
    const retryAfterSec = Math.ceil((entry.lockedUntil - Date.now()) / 1000);
    audit('auth.login.locked', {
      user_type,
      email: maskEmail(email),
      ip: clientIp(req),
      result: 'blocked',
      retry_after_sec: retryAfterSec,
    });
    res.set('Retry-After', String(retryAfterSec));
    return res.status(429).json({
      error: 'Account temporarily locked',
      message: `ログインの失敗が続いたため、一時的にロックされています。約 ${Math.ceil(
        retryAfterSec / 60
      )} 分後に再度お試しください。`,
    });
  }

  return next();
}

/**
 * ログイン失敗を記録する (パスワード不一致・存在しないアカウントの両方で呼ぶ)
 * @returns {Boolean} 今回の失敗でロックに至ったか
 */
function recordLoginFailure(userType, email) {
  const key = lockoutKey(userType, email);
  const now = Date.now();
  const entry = loginFailures.get(key);

  // 失敗の集計ウィンドウを過ぎていればカウントをやり直す
  if (!entry || now - entry.firstFailedAt > FAILURE_WINDOW_MS) {
    loginFailures.set(key, { count: 1, firstFailedAt: now, lockedUntil: 0 });
    return false;
  }

  entry.count += 1;
  if (entry.count >= LOCKOUT_THRESHOLD) {
    entry.lockedUntil = now + LOCKOUT_DURATION_MS;
    entry.count = 0; // ロック解除後は再度 5 回まで試せる
    entry.firstFailedAt = now;
    return true;
  }
  return false;
}

/**
 * ログイン成功時に失敗カウントを消す
 */
function clearLoginFailures(userType, email) {
  loginFailures.delete(lockoutKey(userType, email));
}

module.exports = {
  authLimiter,
  verifyPinLimiter,
  stripeLimiter,
  loginLockout,
  recordLoginFailure,
  clearLoginFailures,
  LOCKOUT_THRESHOLD,
  LOCKOUT_DURATION_MS,
};
