const { validationResult } = require('express-validator');
const CustomerAddress = require('../models/CustomerAddress');

/**
 * Get customer's addresses
 * GET /api/customers/:customerId/addresses
 */
exports.getAddresses = async (req, res) => {
  try {
    const { customerId } = req.params;
    const customer_id = req.user.id;

    // Ensure customer can only access their own addresses
    if (parseInt(customerId) !== customer_id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const addresses = await CustomerAddress.findAll({
      where: { customer_id },
      order: [
        ['is_default', 'DESC'],
        ['created_at', 'DESC'],
      ],
    });

    res.json({
      addresses,
      total: addresses.length,
    });
  } catch (error) {
    console.error('Get addresses error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Add new address
 * POST /api/customers/:customerId/addresses
 */
exports.addAddress = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { customerId } = req.params;
    const customer_id = req.user.id;

    if (parseInt(customerId) !== customer_id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const {
      address_line,
      city,
      postal_code,
      latitude,
      longitude,
      is_default,
      label,
    } = req.body;

    // If this is set as default, unset other defaults
    if (is_default) {
      await CustomerAddress.update(
        { is_default: false },
        { where: { customer_id } }
      );
    }

    const address = await CustomerAddress.create({
      customer_id,
      address_line,
      city,
      postal_code,
      latitude,
      longitude,
      is_default: is_default || false,
      label: label || 'Home',
    });

    res.status(201).json({
      message: 'Address added successfully',
      address,
    });
  } catch (error) {
    console.error('Add address error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update address
 * PUT /api/addresses/:id
 */
exports.updateAddress = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const customer_id = req.user.id;

    const address = await CustomerAddress.findOne({
      where: { id, customer_id },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found' });
    }

    const {
      address_line,
      city,
      postal_code,
      latitude,
      longitude,
      label,
    } = req.body;

    await address.update({
      address_line,
      city,
      postal_code,
      latitude,
      longitude,
      label,
    });

    res.json({
      message: 'Address updated successfully',
      address,
    });
  } catch (error) {
    console.error('Update address error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Delete address
 * DELETE /api/addresses/:id
 */
exports.deleteAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const address = await CustomerAddress.findOne({
      where: { id, customer_id },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found' });
    }

    await address.destroy();

    res.json({
      message: 'Address deleted successfully',
    });
  } catch (error) {
    console.error('Delete address error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Set address as default
 * PATCH /api/addresses/:id/default
 */
exports.setDefaultAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const customer_id = req.user.id;

    const address = await CustomerAddress.findOne({
      where: { id, customer_id },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found' });
    }

    // Unset all other defaults
    await CustomerAddress.update(
      { is_default: false },
      { where: { customer_id } }
    );

    // Set this as default
    await address.update({ is_default: true });

    res.json({
      message: 'Default address set successfully',
      address,
    });
  } catch (error) {
    console.error('Set default address error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
