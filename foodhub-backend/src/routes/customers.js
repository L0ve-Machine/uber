const express = require('express');
const { body } = require('express-validator');
const customerController = require('../controllers/customerController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const updateProfileValidation = [
  body('full_name')
    .optional()
    .isLength({ min: 2, max: 100 })
    .withMessage('Name must be between 2 and 100 characters'),
  body('phone')
    .optional()
    .matches(/^[\d\-+() ]+$/)
    .withMessage('Invalid phone number format'),
  body('profile_image_url')
    .optional()
    .isURL()
    .withMessage('Invalid URL format'),
];

const changePasswordValidation = [
  body('current_password')
    .notEmpty()
    .withMessage('Current password is required'),
  body('new_password')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters'),
];

/**
 * @route   GET /api/customers/profile
 * @desc    Get customer profile
 * @access  Private (Customer only)
 */
router.get(
  '/profile',
  authMiddleware,
  isCustomer,
  customerController.getProfile
);

/**
 * @route   PUT /api/customers/profile
 * @desc    Update customer profile
 * @access  Private (Customer only)
 */
router.put(
  '/profile',
  authMiddleware,
  isCustomer,
  updateProfileValidation,
  customerController.updateProfile
);

/**
 * @route   PATCH /api/customers/password
 * @desc    Change customer password
 * @access  Private (Customer only)
 */
router.patch(
  '/password',
  authMiddleware,
  isCustomer,
  changePasswordValidation,
  customerController.changePassword
);

module.exports = router;
