const express = require('express');
const { body } = require('express-validator');
const favoriteController = require('../controllers/favoriteController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const addFavoriteValidation = [
  body('restaurant_id').isInt().withMessage('Valid restaurant ID is required'),
];

/**
 * @route   GET /api/favorites
 * @desc    Get customer's favorites
 * @access  Private (Customer only)
 */
router.get(
  '/',
  authMiddleware,
  isCustomer,
  favoriteController.getFavorites
);

/**
 * @route   POST /api/favorites
 * @desc    Add restaurant to favorites
 * @access  Private (Customer only)
 */
router.post(
  '/',
  authMiddleware,
  isCustomer,
  addFavoriteValidation,
  favoriteController.addFavorite
);

/**
 * @route   DELETE /api/favorites/:id
 * @desc    Remove restaurant from favorites
 * @access  Private (Customer only)
 */
router.delete(
  '/:id',
  authMiddleware,
  isCustomer,
  favoriteController.removeFavorite
);

module.exports = router;
