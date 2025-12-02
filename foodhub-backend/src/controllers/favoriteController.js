const { validationResult } = require('express-validator');
const Favorite = require('../models/Favorite');
const Restaurant = require('../models/Restaurant');

/**
 * Get customer's favorites
 * GET /api/favorites
 */
exports.getFavorites = async (req, res) => {
  try {
    const customer_id = req.user.id;

    const favorites = await Favorite.findAll({
      where: { customer_id },
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: {
            exclude: ['password_hash'],
          },
        },
      ],
      order: [['created_at', 'DESC']],
    });

    res.json({
      favorites,
      total: favorites.length,
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Add restaurant to favorites
 * POST /api/favorites
 */
exports.addFavorite = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { restaurant_id } = req.body;
    const customer_id = req.user.id;

    // Check if restaurant exists
    const restaurant = await Restaurant.findByPk(restaurant_id);
    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({
      where: { customer_id, restaurant_id },
    });

    if (existingFavorite) {
      return res.status(409).json({ error: 'Restaurant already in favorites' });
    }

    const favorite = await Favorite.create({
      customer_id,
      restaurant_id,
    });

    // Fetch favorite with restaurant data
    const favoriteWithRestaurant = await Favorite.findByPk(favorite.id, {
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: {
            exclude: ['password_hash'],
          },
        },
      ],
    });

    res.status(201).json({
      message: 'Restaurant added to favorites',
      favorite: favoriteWithRestaurant,
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Remove restaurant from favorites
 * DELETE /api/favorites/:id
 */
exports.removeFavorite = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const favorite = await Favorite.findOne({
      where: { id, customer_id },
    });

    if (!favorite) {
      return res.status(404).json({ error: 'Favorite not found' });
    }

    await favorite.destroy();

    res.json({
      message: 'Restaurant removed from favorites',
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
