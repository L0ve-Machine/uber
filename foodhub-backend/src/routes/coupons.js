const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const couponController = require('../controllers/couponController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

// Validation rules
const validateCouponValidation = [
  body('code')
    .notEmpty()
    .withMessage('クーポンコードは必須です')
    .isLength({ max: 50 })
    .withMessage('クーポンコードは50文字以内で入力してください'),
  body('subtotal')
    .notEmpty()
    .withMessage('小計は必須です')
    .isNumeric()
    .withMessage('小計は数値で指定してください'),
];

// All routes require authentication and customer role
router.use(authMiddleware, isCustomer);

// Validate a coupon code
router.post('/validate', validateCouponValidation, couponController.validateCoupon);

// Get available coupons for the current user
router.get('/available', couponController.getAvailableCoupons);

module.exports = router;
