const path = require('path');
const fs = require('fs').promises;
const MenuItem = require('../models/MenuItem');
const Restaurant = require('../models/Restaurant');
const { audit, clientIp } = require('../utils/audit');

/** アップロード画像の実体を置くディレクトリ (絶対パス) */
const UPLOADS_ROOT = path.resolve(__dirname, '../../uploads');

/**
 * 削除対象ファイルの絶対パスを組み立てる。
 * ファイル名は path.basename で正規化し、さらに解決後のパスが
 * uploads/ 配下に収まっていることを確認する (ASVS V4.2 / V5.4)。
 *
 * @param {String} imageUrl - クライアントから渡された画像 URL
 * @returns {String|null} 安全な絶対パス。uploads/ の外に出る場合は null
 */
function resolveUploadPath(imageUrl) {
  const filename = path.basename(imageUrl);

  // 空・カレント・親ディレクトリ参照は弾く
  if (!filename || filename === '.' || filename === '..') {
    return null;
  }

  // フォルダはホワイトリストの 2 択に固定
  const folder = imageUrl.includes('/restaurants/') ? 'restaurants' : 'menu-items';

  const filePath = path.resolve(UPLOADS_ROOT, folder, filename);

  // シンボリックリンク等で uploads/ の外に出ていないか最終確認
  const prefix = UPLOADS_ROOT + path.sep;
  if (!filePath.startsWith(prefix)) {
    return null;
  }

  return filePath;
}

/**
 * この画像が呼び出し元の店舗のものか確認する (IDOR 対策 / ASVS V4.2)
 *
 * - メニュー画像: 自店舗の MenuItem.image_url に一致するか
 * - 店舗画像: 自店舗の cover_image_url / logo_url に一致するか
 *
 * @param {String} imageUrl
 * @param {Number} restaurantId - JWT 由来の店舗 ID
 * @returns {Promise<Boolean>}
 */
async function isOwnedByRestaurant(imageUrl, restaurantId) {
  const menuItem = await MenuItem.findOne({
    where: { image_url: imageUrl, restaurant_id: restaurantId },
  });
  if (menuItem) return true;

  const restaurant = await Restaurant.findByPk(restaurantId);
  if (
    restaurant &&
    (restaurant.cover_image_url === imageUrl || restaurant.logo_url === imageUrl)
  ) {
    return true;
  }

  return false;
}

/**
 * Upload menu item images
 * POST /api/upload/menu-images
 */
exports.uploadMenuImages = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No images uploaded' });
    }

    // Generate URLs for uploaded images
    const imageUrls = req.files.map(file => {
      return `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/uploads/menu-items/${file.filename}`;
    });

    console.log(`[UPLOAD] Uploaded ${req.files.length} menu images`);

    res.json({
      message: 'Images uploaded successfully',
      image_urls: imageUrls,
    });
  } catch (error) {
    console.error('Upload menu images error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Upload restaurant images (cover/logo)
 * POST /api/upload/restaurant-images
 */
exports.uploadRestaurantImages = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: 'No images uploaded' });
    }

    // Generate URLs for uploaded images
    const imageUrls = req.files.map(file => {
      return `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/uploads/restaurants/${file.filename}`;
    });

    console.log(`[UPLOAD] Uploaded ${req.files.length} restaurant images`);

    res.json({
      message: 'Images uploaded successfully',
      image_urls: imageUrls,
    });
  } catch (error) {
    console.error('Upload restaurant images error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Delete uploaded image
 * DELETE /api/upload/image
 */
exports.deleteImage = async (req, res) => {
  try {
    const { image_url } = req.body;
    const restaurantId = req.user.id; // ロールは isRestaurant で保証済み

    if (!image_url || typeof image_url !== 'string') {
      return res.status(400).json({ error: 'Image URL is required' });
    }

    // 1) 所有者チェック: 自店舗に紐づく画像でなければ削除させない (ASVS V4.2)
    //    これが無いと、任意の店舗アカウントで他店舗の画像を削除できてしまう。
    const owned = await isOwnedByRestaurant(image_url, restaurantId);
    if (!owned) {
      audit('upload.delete.denied', {
        actor_type: 'restaurant',
        actor_id: restaurantId,
        target: path.basename(image_url),
        ip: clientIp(req),
        result: 'denied',
      });
      // 他店舗の画像の存在有無を漏らさないため 404 で統一する
      return res.status(404).json({ error: 'Image not found' });
    }

    // 2) パス解決: basename で正規化し uploads/ 配下に収まることを確認
    const filePath = resolveUploadPath(image_url);
    if (!filePath) {
      return res.status(400).json({ error: 'Invalid image URL' });
    }

    // Check if file exists and delete
    try {
      await fs.access(filePath);
      await fs.unlink(filePath);
      audit('upload.delete', {
        actor_type: 'restaurant',
        actor_id: restaurantId,
        target: path.basename(filePath),
        ip: clientIp(req),
        result: 'success',
      });

      res.json({
        message: 'Image deleted successfully',
      });
    } catch (error) {
      // File doesn't exist or already deleted
      res.json({
        message: 'Image not found or already deleted',
      });
    }
  } catch (error) {
    console.error('Delete image error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
