/**
 * 監査ログユーティリティ (ASVS V7.2)
 *
 * 「いつ・誰が・何を・結果はどうだったか」を 1 行 1 JSON (JSON Lines) で
 * 標準出力に書き出す。pm2 のログファイルがそのまま監査証跡になる。
 *
 * 出力してよいのは識別子とマスク済みメールのみ。
 * パスワード・トークン・ピックアップ PIN・カード情報は絶対に渡さないこと。
 */

/**
 * メールアドレスをマスクする (例: customer@test.com -> c*******@test.com)
 * 監査時の突き合わせは可能にしつつ、ログ流出時の被害を抑える。
 * @param {String} email
 * @returns {String} マスク済みメール
 */
function maskEmail(email) {
  if (typeof email !== 'string' || !email.includes('@')) {
    return '(unknown)';
  }
  const [local, domain] = email.split('@');
  const head = local.slice(0, 1);
  return `${head}${'*'.repeat(Math.max(local.length - 1, 1))}@${domain}`;
}

/**
 * 監査イベントを 1 行の JSON として出力する
 * @param {String} action - イベント名 (例: 'auth.login.success')
 * @param {Object} fields - 付随情報 (actor_type / actor_id / target_id / result / ip など)
 */
function audit(action, fields = {}) {
  const entry = {
    ts: new Date().toISOString(),
    kind: 'audit',
    action,
    ...fields,
  };
  // JSON Lines 形式。ログ収集基盤に流し込む際はこの 1 行をそのままパースできる。
  console.log(`[AUDIT] ${JSON.stringify(entry)}`);
}

/**
 * リクエストから接続元 IP を取得する
 * app.set('trust proxy', 1) 済みなので req.ip はホスト nginx が付けた
 * X-Forwarded-For の最終ホップ (実クライアント IP) になる。
 * @param {Object} req - Express の Request
 * @returns {String}
 */
function clientIp(req) {
  return (req && req.ip) || '(unknown)';
}

module.exports = { audit, maskEmail, clientIp };
