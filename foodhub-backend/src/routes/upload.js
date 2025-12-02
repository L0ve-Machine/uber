const express = require('express');
const uploadController = require('../controllers/uploadController');
const { uploadMenuImages, uploadRestaurantImages } = require('../config/multer');
const { authMiddleware, isRestaurant } = require('../middleware/auth');

const router = express.Router();

// All upload routes require restaurant authentication
router.use(authMiddleware);
router.use(isRestaurant);

/**
 * @route   POST /api/upload/menu-images
 * @desc    Upload menu item images (up to 10 images)
 * @access  Private (Restaurant only)
 */
router.post('/menu-images', (req, res) => {
  uploadMenuImages(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    uploadController.uploadMenuImages(req, res);
  });
});

/**
 * @route   POST /api/upload/restaurant-images
 * @desc    Upload restaurant images (up to 5 images)
 * @access  Private (Restaurant only)
 */
router.post('/restaurant-images', (req, res) => {
  uploadRestaurantImages(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    uploadController.uploadRestaurantImages(req, res);
  });
});

/**
 * @route   DELETE /api/upload/image
 * @desc    Delete uploaded image
 * @access  Private (Restaurant only)
 */
router.delete('/image', uploadController.deleteImage);

module.exports = router;
