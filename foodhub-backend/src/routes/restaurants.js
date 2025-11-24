const express = require('express');
const restaurantController = require('../controllers/restaurantController');

const router = express.Router();

/**
 * @route   GET /api/restaurants
 * @desc    Get all restaurants (with optional filters)
 * @access  Public
 * @query   category, search, lat, lng, radius
 */
router.get('/', restaurantController.getRestaurants);

/**
 * @route   GET /api/restaurants/:id
 * @desc    Get restaurant by ID
 * @access  Public
 */
router.get('/:id', restaurantController.getRestaurantById);

/**
 * @route   GET /api/restaurants/:id/menu
 * @desc    Get restaurant menu
 * @access  Public
 * @query   category
 */
router.get('/:id/menu', restaurantController.getRestaurantMenu);

module.exports = router;
