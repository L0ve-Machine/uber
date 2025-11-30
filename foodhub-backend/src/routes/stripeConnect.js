const express = require('express');
const stripeConnectController = require('../controllers/stripeConnectController');
const { authMiddleware, isRestaurant, isDriver } = require('../middleware/auth');

const router = express.Router();

/**
 * @route   POST /api/stripe/connect/restaurant
 * @desc    Create Stripe Connect account for restaurant
 * @access  Private (Restaurant only)
 */
router.post(
  '/connect/restaurant',
  authMiddleware,
  isRestaurant,
  stripeConnectController.createRestaurantAccount
);

/**
 * @route   POST /api/stripe/connect/driver
 * @desc    Create Stripe Connect account for driver
 * @access  Private (Driver only)
 */
router.post(
  '/connect/driver',
  authMiddleware,
  isDriver,
  stripeConnectController.createDriverAccount
);

/**
 * @route   GET /api/stripe/status
 * @desc    Get Stripe account status
 * @access  Private (Restaurant or Driver)
 */
router.get('/status', authMiddleware, stripeConnectController.getAccountStatus);

/**
 * @route   POST /webhook/stripe/connect
 * @desc    Handle Stripe Connect webhook events
 * @access  Public (Stripe only)
 */
router.post('/webhook/connect', express.raw({ type: 'application/json' }), stripeConnectController.handleConnectWebhook);

module.exports = router;
