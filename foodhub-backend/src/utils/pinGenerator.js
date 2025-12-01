/**
 * ピックアップPIN生成ユーティリティ
 */

/**
 * 4桁のランダムPINを生成
 * @returns {string} 4桁の数字文字列 (1000-9999)
 */
function generatePickupPin() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

module.exports = { generatePickupPin };
