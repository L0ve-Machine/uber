/**
 * JWT 失効リスト (ASVS V3.3)
 *
 * ログアウト時に、そのトークンの jti (JWT ID) を失効リストへ登録する。
 * 認証ミドルウェアが毎リクエストで照合し、失効済みなら 401 を返す。
 *
 * ⚠️ この実装はプロセス内メモリのみ。以下の制約がある:
 *   - pm2 の cluster モードや複数インスタンスに増やすと、
 *     ログアウトしたプロセス以外では失効が効かない。
 *   - プロセス再起動で失効リストが消える
 *     (ただし再起動時は全トークンが有効なままなので、
 *      「失効したはずのトークンが復活する」点に注意)。
 *   マルチプロセス構成にする場合は、この Map を Redis
 *   (SET jti "1" EX <残存秒数>) に置き換えること。
 *   現状は pm2 fork モード 1 プロセス運用のため、この実装で要件を満たす。
 */

/** @type {Map<string, number>} jti -> 失効解除できる時刻 (epoch ミリ秒 = 元トークンの exp) */
const denylist = new Map();

/**
 * トークンを失効させる
 * @param {String} jti - JWT の jti クレーム
 * @param {Number} expSeconds - JWT の exp クレーム (epoch 秒)
 */
function revokeToken(jti, expSeconds) {
  if (!jti) return;
  // exp が無い/不正な場合も、既定の 7 日間は保持して安全側に倒す
  const expiresAtMs =
    typeof expSeconds === 'number' && Number.isFinite(expSeconds)
      ? expSeconds * 1000
      : Date.now() + 7 * 24 * 60 * 60 * 1000;
  denylist.set(jti, expiresAtMs);
}

/**
 * トークンが失効済みか判定する
 * @param {String} jti
 * @returns {Boolean}
 */
function isTokenRevoked(jti) {
  if (!jti) return false;
  const expiresAtMs = denylist.get(jti);
  if (expiresAtMs === undefined) return false;
  if (expiresAtMs <= Date.now()) {
    // 元トークン自体が期限切れ。もう保持する意味がないので削除
    denylist.delete(jti);
    return false;
  }
  return true;
}

/**
 * 期限切れエントリを掃除する (メモリリーク防止)
 * @returns {Number} 削除件数
 */
function purgeExpired() {
  const now = Date.now();
  let removed = 0;
  for (const [jti, expiresAtMs] of denylist) {
    if (expiresAtMs <= now) {
      denylist.delete(jti);
      removed += 1;
    }
  }
  return removed;
}

// 1 時間ごとに掃除。unref() によりこのタイマーがプロセスを生かし続けることはない。
const purgeTimer = setInterval(purgeExpired, 60 * 60 * 1000);
if (typeof purgeTimer.unref === 'function') {
  purgeTimer.unref();
}

module.exports = { revokeToken, isTokenRevoked, purgeExpired };
