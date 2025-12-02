const { validationResult } = require('express-validator');
const { Op } = require('sequelize');
const Restaurant = require('../models/Restaurant');
const MenuItem = require('../models/MenuItem');
const MenuItemOption = require('../models/MenuItemOption');

/**
 * Get all restaurants with optional filters
 * GET /api/restaurants?category=Japanese&search=sushi&lat=35.6581&lng=139.7017
 */
exports.getRestaurants = async (req, res) => {
  try {
    const { category, search, lat, lng, radius = 10 } = req.query;

    // Build where clause
    const where = {
      is_approved: true, // Only approved restaurants
      stripe_payouts_enabled: true, // Only restaurants with Stripe setup completed
    };

    if (category) {
      where.category = category;
    }

    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
      ];
    }

    // TODO: Add geolocation filtering based on lat, lng, radius
    // For now, we'll return all matching restaurants

    const restaurants = await Restaurant.findAll({
      where,
      attributes: {
        exclude: ['password_hash'],
      },
      order: [
        ['rating', 'DESC'],
        ['total_reviews', 'DESC'],
      ],
    });

    res.json({
      restaurants,
      total: restaurants.length,
    });
  } catch (error) {
    console.error('Get restaurants error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get restaurant by ID
 * GET /api/restaurants/:id
 */
exports.getRestaurantById = async (req, res) => {
  try {
    const { id } = req.params;

    const restaurant = await Restaurant.findByPk(id, {
      attributes: {
        exclude: ['password_hash'],
      },
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    if (!restaurant.is_approved) {
      return res.status(403).json({ error: 'Restaurant not approved yet' });
    }

    res.json(restaurant);
  } catch (error) {
    console.error('Get restaurant by ID error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get restaurant menu
 * GET /api/restaurants/:id/menu?category=Main
 */
exports.getRestaurantMenu = async (req, res) => {
  try {
    const { id } = req.params;
    const { category } = req.query;

    // Check if restaurant exists and is approved
    const restaurant = await Restaurant.findByPk(id);
    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }
    if (!restaurant.is_approved) {
      return res.status(403).json({ error: 'Restaurant not approved yet' });
    }

    // Build where clause
    const where = {
      restaurant_id: id,
    };

    if (category) {
      where.category = category;
    }

    const menuItems = await MenuItem.findAll({
      where,
      include: [
        {
          model: MenuItemOption,
          as: 'options',
          required: false,
        },
      ],
      order: [
        ['category', 'ASC'],
        ['name', 'ASC'],
      ],
    });

    res.json({
      restaurant_id: parseInt(id),
      restaurant_name: restaurant.name,
      menu_items: menuItems,
      total: menuItems.length,
    });
  } catch (error) {
    console.error('Get restaurant menu error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get menu item by ID
 * GET /api/menu-items/:id
 */
exports.getMenuItemById = async (req, res) => {
  try {
    const { id } = req.params;

    const menuItem = await MenuItem.findByPk(id, {
      include: [
        {
          model: MenuItemOption,
          as: 'options',
          required: false,
        },
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'category'],
        },
      ],
    });

    if (!menuItem) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    res.json(menuItem);
  } catch (error) {
    console.error('Get menu item by ID error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get restaurant profile (with Stripe status)
 * GET /api/restaurant/profile
 */
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;

    const restaurant = await Restaurant.findOne({
      where: { id: userId },
      attributes: {
        exclude: ['password_hash'],
      },
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    res.json({
      id: restaurant.id,
      email: restaurant.email,
      name: restaurant.name,
      description: restaurant.description,
      category: restaurant.category,
      address: restaurant.address,
      phone: restaurant.phone,
      image_url: restaurant.image_url,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      rating: restaurant.rating,
      total_reviews: restaurant.total_reviews,
      is_approved: restaurant.is_approved,
      stripe_account_id: restaurant.stripe_account_id,
      stripe_onboarding_completed: restaurant.stripe_onboarding_completed,
      stripe_charges_enabled: restaurant.stripe_charges_enabled,
      stripe_payouts_enabled: restaurant.stripe_payouts_enabled,
      commission_rate: restaurant.commission_rate,
      created_at: restaurant.created_at,
      updated_at: restaurant.updated_at,
    });
  } catch (error) {
    console.error('Get restaurant profile error:', error);
    res.status(500).json({ error: 'Failed to get restaurant profile' });
  }
};
