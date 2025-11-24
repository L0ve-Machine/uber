const { validationResult } = require('express-validator');
const MenuItem = require('../models/MenuItem');
const MenuItemOption = require('../models/MenuItemOption');

/**
 * Get restaurant's own menu
 * GET /api/restaurant/menu?category=Main
 */
exports.getOwnMenu = async (req, res) => {
  try {
    const restaurant_id = req.user.id;
    const { category } = req.query;

    const where = { restaurant_id };
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
      menu_items: menuItems,
      total: menuItems.length,
    });
  } catch (error) {
    console.error('Get own menu error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Add menu item
 * POST /api/restaurant/menu
 */
exports.addMenuItem = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const restaurant_id = req.user.id;
    const { name, description, price, category, image_url, options } = req.body;

    const menuItem = await MenuItem.create({
      restaurant_id,
      name,
      description,
      price,
      category,
      image_url,
      is_available: true,
    });

    // Add options if provided
    if (options && options.length > 0) {
      for (const option of options) {
        await MenuItemOption.create({
          menu_item_id: menuItem.id,
          option_group_name: option.option_group_name,
          option_name: option.option_name,
          additional_price: option.additional_price || 0,
        });
      }
    }

    // Fetch complete menu item with options
    const completeMenuItem = await MenuItem.findByPk(menuItem.id, {
      include: [
        {
          model: MenuItemOption,
          as: 'options',
        },
      ],
    });

    res.status(201).json({
      message: 'Menu item added successfully',
      menu_item: completeMenuItem,
    });
  } catch (error) {
    console.error('Add menu item error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update menu item
 * PUT /api/restaurant/menu/:id
 */
exports.updateMenuItem = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const restaurant_id = req.user.id;

    const menuItem = await MenuItem.findOne({
      where: { id, restaurant_id },
    });

    if (!menuItem) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    const { name, description, price, category, image_url, is_available } = req.body;

    await menuItem.update({
      name,
      description,
      price,
      category,
      image_url,
      is_available,
    });

    res.json({
      message: 'Menu item updated successfully',
      menu_item: menuItem,
    });
  } catch (error) {
    console.error('Update menu item error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Delete menu item
 * DELETE /api/restaurant/menu/:id
 */
exports.deleteMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant_id = req.user.id;

    const menuItem = await MenuItem.findOne({
      where: { id, restaurant_id },
    });

    if (!menuItem) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    await menuItem.destroy();

    res.json({
      message: 'Menu item deleted successfully',
    });
  } catch (error) {
    console.error('Delete menu item error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Toggle menu item availability
 * PATCH /api/restaurant/menu/:id/availability
 */
exports.toggleAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const restaurant_id = req.user.id;

    const menuItem = await MenuItem.findOne({
      where: { id, restaurant_id },
    });

    if (!menuItem) {
      return res.status(404).json({ error: 'Menu item not found' });
    }

    await menuItem.update({
      is_available: !menuItem.is_available,
    });

    res.json({
      message: 'Availability updated successfully',
      menu_item: menuItem,
    });
  } catch (error) {
    console.error('Toggle availability error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
