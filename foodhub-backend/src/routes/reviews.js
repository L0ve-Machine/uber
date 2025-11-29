const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const reviewController = require('../controllers/reviewController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

// Validation rules
const createReviewValidation = [
  body('order_id')
    .notEmpty()
    .withMessage('注文IDは必須です')
    .isInt()
    .withMessage('注文IDは数値で指定してください'),
  body('rating')
    .notEmpty()
    .withMessage('評価は必須です')
    .isInt({ min: 1, max: 5 })
    .withMessage('評価は1〜5の数値で指定してください'),
  body('comment')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('コメントは1000文字以内で入力してください'),
];

const updateReviewValidation = [
  body('rating')
    .notEmpty()
    .withMessage('評価は必須です')
    .isInt({ min: 1, max: 5 })
    .withMessage('評価は1〜5の数値で指定してください'),
  body('comment')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('コメントは1000文字以内で入力してください'),
];

// Public routes
// Get reviews for a restaurant
router.get('/restaurant/:restaurantId', reviewController.getRestaurantReviews);

// Protected routes (customer only)
// Create a review
router.post('/', authMiddleware, isCustomer, createReviewValidation, reviewController.createReview);

// Get my reviews
router.get('/my', authMiddleware, isCustomer, reviewController.getMyReviews);

// Check if order can be reviewed
router.get('/can-review/:orderId', authMiddleware, isCustomer, reviewController.canReview);

// Update a review
router.put('/:id', authMiddleware, isCustomer, updateReviewValidation, reviewController.updateReview);

// Delete a review
router.delete('/:id', authMiddleware, isCustomer, reviewController.deleteReview);

module.exports = router;
