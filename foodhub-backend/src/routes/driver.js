const express = require('express');
const { body } = require('express-validator');
const driverController = require('../controllers/driverController');
const { authMiddleware, isDriver } = require('../middleware/auth');

const router = express.Router();

// All routes require driver authentication
router.use(authMiddleware);
router.use(isDriver);

// ==================== Profile ====================

/**
 * @route   GET /api/driver/profile
 * @desc    Get driver profile (with Stripe status)
 * @access  Private (Driver only)
 */
router.get('/profile', driverController.getProfile);

// ==================== Orders ====================

/**
 * @route   GET /api/driver/available-orders
 * @desc    Get available orders for pickup
 * @access  Private (Driver only)
 */
router.get('/available-orders', driverController.getAvailableOrders);

/**
 * @route   GET /api/driver/orders
 * @desc    Get driver's assigned orders
 * @access  Private (Driver only)
 * @query   status
 */
router.get('/orders', driverController.getDriverOrders);

/**
 * @route   POST /api/driver/orders/:id/accept
 * @desc    Accept delivery
 * @access  Private (Driver only)
 */
router.post('/orders/:id/accept', driverController.acceptDelivery);

/**
 * @route   PATCH /api/driver/orders/:id/status
 * @desc    Update delivery status
 * @access  Private (Driver only)
 */
router.patch(
  '/orders/:id/status',
  [body('status').isIn(['delivering', 'delivered']).withMessage('Invalid status')],
  driverController.updateDeliveryStatus
);

/**
 * @route   POST /api/driver/orders/:id/verify-pin
 * @desc    Verify pickup PIN
 * @access  Private (Driver only)
 */
router.post(
  '/orders/:id/verify-pin',
  [body('pin').isLength({ min: 4, max: 4 }).withMessage('PIN must be 4 digits')],
  driverController.verifyPickupPin
);

// ==================== Driver Management ====================

/**
 * @route   PATCH /api/driver/location
 * @desc    Update driver location
 * @access  Private (Driver only)
 */
router.patch(
  '/location',
  [
    body('latitude').isFloat().withMessage('Valid latitude is required'),
    body('longitude').isFloat().withMessage('Valid longitude is required'),
  ],
  driverController.updateLocation
);

/**
 * @route   PATCH /api/driver/online
 * @desc    Toggle online status
 * @access  Private (Driver only)
 */
router.patch(
  '/online',
  [body('is_online').isBoolean().withMessage('Valid boolean is required')],
  driverController.toggleOnlineStatus
);

/**
 * @route   GET /api/driver/stats
 * @desc    Get driver statistics
 * @access  Private (Driver only)
 * @query   period (today, week, month)
 */
router.get('/stats', driverController.getDriverStats);

module.exports = router;
