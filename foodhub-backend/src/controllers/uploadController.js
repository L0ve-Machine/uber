const path = require('path');
const fs = require('fs').promises;

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

    if (!image_url) {
      return res.status(400).json({ error: 'Image URL is required' });
    }

    // Extract filename from URL
    const filename = path.basename(image_url);

    // Determine folder (menu-items or restaurants)
    let folder = 'menu-items';
    if (image_url.includes('/restaurants/')) {
      folder = 'restaurants';
    }

    const filePath = path.join(__dirname, '../../uploads', folder, filename);

    // Check if file exists and delete
    try {
      await fs.access(filePath);
      await fs.unlink(filePath);
      console.log(`[UPLOAD] Deleted image: ${filename}`);

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
