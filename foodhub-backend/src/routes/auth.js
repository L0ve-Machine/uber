const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const loginValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required'),
  body('user_type')
    .isIn(['customer', 'restaurant', 'driver'])
    .withMessage('Invalid user type'),
];

const customerRegisterValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('full_name').notEmpty().withMessage('Full name is required'),
  body('phone').notEmpty().withMessage('Phone number is required'),
];

const restaurantRegisterValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('name').notEmpty().withMessage('Restaurant name is required'),
  body('category').notEmpty().withMessage('Category is required'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('address').notEmpty().withMessage('Address is required'),
  body('latitude').isFloat().withMessage('Valid latitude is required'),
  body('longitude').isFloat().withMessage('Valid longitude is required'),
];

const driverRegisterValidation = [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('full_name').notEmpty().withMessage('Full name is required'),
  body('phone').notEmpty().withMessage('Phone number is required'),
  body('vehicle_type').notEmpty().withMessage('Vehicle type is required'),
];

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', loginValidation, authController.login);

/**
 * @route   POST /api/auth/register/customer
 * @desc    Register new customer
 * @access  Public
 */
router.post(
  '/register/customer',
  customerRegisterValidation,
  authController.registerCustomer
);

/**
 * @route   POST /api/auth/register/restaurant
 * @desc    Register new restaurant
 * @access  Public
 */
router.post(
  '/register/restaurant',
  restaurantRegisterValidation,
  authController.registerRestaurant
);

/**
 * @route   POST /api/auth/register/driver
 * @desc    Register new driver
 * @access  Public
 */
router.post(
  '/register/driver',
  driverRegisterValidation,
  authController.registerDriver
);

/**
 * @route   GET /api/auth/me
 * @desc    Get current user
 * @access  Private
 */
router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
