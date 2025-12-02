const express = require('express');
const { body } = require('express-validator');
const restaurantDashboardController = require('../controllers/restaurantDashboardController');
const restaurantMenuController = require('../controllers/restaurantMenuController');
const restaurantController = require('../controllers/restaurantController');
const { authMiddleware, isRestaurant } = require('../middleware/auth');

const router = express.Router();

// All routes require restaurant authentication
router.use(authMiddleware);
router.use(isRestaurant);

// ==================== Profile ====================

/**
 * @route   GET /api/restaurant/profile
 * @desc    Get restaurant profile (with Stripe status)
 * @access  Private (Restaurant only)
 */
router.get('/profile', restaurantController.getProfile);

/**
 * @route   PATCH /api/restaurant/password
 * @desc    Change restaurant password
 * @access  Private (Restaurant only)
 */
router.patch(
  '/password',
  [
    body('current_password').notEmpty().withMessage('Current password is required'),
    body('new_password').isLength({ min: 8 }).withMessage('New password must be at least 8 characters'),
  ],
  restaurantController.changePassword
);

// ==================== Orders ====================

/**
 * @route   GET /api/restaurant/orders
 * @desc    Get restaurant's orders
 * @access  Private (Restaurant only)
 * @query   status
 */
router.get('/orders', restaurantDashboardController.getRestaurantOrders);

/**
 * @route   GET /api/restaurant/orders/:id
 * @desc    Get order detail
 * @access  Private (Restaurant only)
 */
router.get('/orders/:id', restaurantDashboardController.getRestaurantOrderDetail);

/**
 * @route   PATCH /api/restaurant/orders/:id/accept
 * @desc    Accept order
 * @access  Private (Restaurant only)
 */
router.patch('/orders/:id/accept', restaurantDashboardController.acceptOrder);

/**
 * @route   PATCH /api/restaurant/orders/:id/reject
 * @desc    Reject order
 * @access  Private (Restaurant only)
 */
router.patch('/orders/:id/reject', restaurantDashboardController.rejectOrder);

/**
 * @route   PATCH /api/restaurant/orders/:id/status
 * @desc    Update order status
 * @access  Private (Restaurant only)
 */
router.patch(
  '/orders/:id/status',
  [body('status').isIn(['preparing', 'ready']).withMessage('Invalid status')],
  restaurantDashboardController.updateOrderStatus
);

/**
 * @route   GET /api/restaurant/stats
 * @desc    Get restaurant statistics
 * @access  Private (Restaurant only)
 * @query   period (today, week, month)
 */
router.get('/stats', restaurantDashboardController.getRestaurantStats);

// ==================== Menu Management ====================

/**
 * @route   GET /api/restaurant/menu
 * @desc    Get restaurant's own menu
 * @access  Private (Restaurant only)
 * @query   category
 */
router.get('/menu', restaurantMenuController.getOwnMenu);

/**
 * @route   POST /api/restaurant/menu
 * @desc    Add menu item
 * @access  Private (Restaurant only)
 */
router.post(
  '/menu',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('price').isFloat({ min: 0 }).withMessage('Valid price is required'),
    body('category').notEmpty().withMessage('Category is required'),
  ],
  restaurantMenuController.addMenuItem
);

/**
 * @route   PUT /api/restaurant/menu/:id
 * @desc    Update menu item
 * @access  Private (Restaurant only)
 */
router.put(
  '/menu/:id',
  [
    body('name').notEmpty().withMessage('Name is required'),
    body('price').isFloat({ min: 0 }).withMessage('Valid price is required'),
    body('category').notEmpty().withMessage('Category is required'),
  ],
  restaurantMenuController.updateMenuItem
);

/**
 * @route   DELETE /api/restaurant/menu/:id
 * @desc    Delete menu item
 * @access  Private (Restaurant only)
 */
router.delete('/menu/:id', restaurantMenuController.deleteMenuItem);

/**
 * @route   PATCH /api/restaurant/menu/:id/availability
 * @desc    Toggle menu item availability
 * @access  Private (Restaurant only)
 */
router.patch('/menu/:id/availability', restaurantMenuController.toggleAvailability);

module.exports = router;
