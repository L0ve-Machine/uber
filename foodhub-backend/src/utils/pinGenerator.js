/**
 * ピックアップPIN生成ユーティリティ
 */

const crypto = require('crypto');

/**
 * 4桁のランダムPINを生成
 *
 * PIN は「配達員が店舗で商品を受け取る際の本人確認」というセキュリティ統制なので、
 * 予測可能な Math.random ではなく暗号学的乱数を使う (ASVS V6.2)。
 * crypto.randomInt(min, max) は max 排他なので 1000〜9999 が生成される。
 *
 * @returns {string} 4桁の数字文字列 (1000-9999)
 */
function generatePickupPin() {
  return crypto.randomInt(1000, 10000).toString();
}

module.exports = { generatePickupPin };
