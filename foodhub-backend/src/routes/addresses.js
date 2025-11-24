const express = require('express');
const { body } = require('express-validator');
const addressController = require('../controllers/addressController');
const favoriteController = require('../controllers/favoriteController');
const { authMiddleware, isCustomer } = require('../middleware/auth');

const router = express.Router();

// Validation rules
const addressValidation = [
  body('address_line').notEmpty().withMessage('Address line is required'),
  body('city').notEmpty().withMessage('City is required'),
  body('postal_code').notEmpty().withMessage('Postal code is required'),
];

/**
 * @route   GET /api/customers/:customerId/addresses
 * @desc    Get customer's addresses
 * @access  Private (Customer only)
 */
router.get(
  '/customers/:customerId/addresses',
  authMiddleware,
  isCustomer,
  addressController.getAddresses
);

/**
 * @route   POST /api/customers/:customerId/addresses
 * @desc    Add new address
 * @access  Private (Customer only)
 */
router.post(
  '/customers/:customerId/addresses',
  authMiddleware,
  isCustomer,
  addressValidation,
  addressController.addAddress
);

/**
 * @route   PUT /api/addresses/:id
 * @desc    Update address
 * @access  Private (Customer only)
 */
router.put(
  '/addresses/:id',
  authMiddleware,
  isCustomer,
  addressValidation,
  addressController.updateAddress
);

/**
 * @route   DELETE /api/addresses/:id
 * @desc    Delete address
 * @access  Private (Customer only)
 */
router.delete(
  '/addresses/:id',
  authMiddleware,
  isCustomer,
  addressController.deleteAddress
);

/**
 * @route   PATCH /api/addresses/:id/default
 * @desc    Set address as default
 * @access  Private (Customer only)
 */
router.patch(
  '/addresses/:id/default',
  authMiddleware,
  isCustomer,
  addressController.setDefaultAddress
);

/**
 * @route   GET /api/customers/:customerId/favorites
 * @desc    Get customer's favorites
 * @access  Private (Customer only)
 */
router.get(
  '/customers/:customerId/favorites',
  authMiddleware,
  isCustomer,
  favoriteController.getFavorites
);

module.exports = router;
