const express = require('express');
const restaurantController = require('../controllers/restaurantController');

const router = express.Router();

/**
 * @route   GET /api/menu-items/:id
 * @desc    Get menu item by ID
 * @access  Public
 */
router.get('/:id', restaurantController.getMenuItemById);

module.exports = router;
