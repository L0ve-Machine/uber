const express = require('express');
const { body } = require('express-validator');
const orderController = require('../controllers/orderController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const createOrderValidation = [
  body('restaurant_id').isInt().withMessage('Valid restaurant ID is required'),
  body('delivery_address_id').isInt().withMessage('Valid delivery address ID is required'),
  body('items').isArray({ min: 1 }).withMessage('At least one item is required'),
  body('items.*.menu_item_id').isInt().withMessage('Valid menu item ID is required'),
  body('items.*.quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
  body('payment_method').isIn(['card', 'cash']).withMessage('Invalid payment method'),
];

/**
 * @route   POST /api/orders
 * @desc    Create new order
 * @access  Private (Customer only)
 */
router.post(
  '/',
  authMiddleware,
  isCustomer,
  createOrderValidation,
  orderController.createOrder
);

/**
 * @route   GET /api/orders
 * @desc    Get customer's orders
 * @access  Private (Customer only)
 * @query   status
 */
router.get('/', authMiddleware, isCustomer, orderController.getCustomerOrders);

/**
 * @route   GET /api/orders/:id
 * @desc    Get order by ID
 * @access  Private (Customer only)
 */
router.get('/:id', authMiddleware, isCustomer, orderController.getOrderById);

/**
 * @route   PATCH /api/orders/:id/cancel
 * @desc    Cancel order
 * @access  Private (Customer only)
 */
router.patch('/:id/cancel', authMiddleware, isCustomer, orderController.cancelOrder);

/**
 * @route   GET /api/orders/:id/tracking
 * @desc    Get real-time order tracking info (with privacy protection)
 * @access  Private (Customer only)
 */
router.get('/:id/tracking', authMiddleware, isCustomer, orderController.getOrderTracking);

module.exports = router;
