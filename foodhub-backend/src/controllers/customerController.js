const { validationResult } = require('express-validator');
const Customer = require('../models/Customer');
const { hashPassword, comparePassword } = require('../utils/password');

/**
 * Get customer profile
 * GET /api/customers/profile
 */
exports.getProfile = async (req, res) => {
  try {
    const customer_id = req.user.id;

    const customer = await Customer.findByPk(customer_id, {
      attributes: { exclude: ['password_hash'] },
    });

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    res.json({ user: customer });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Update customer profile
 * PUT /api/customers/profile
 */
exports.updateProfile = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const customer_id = req.user.id;
    const { full_name, phone, profile_image_url } = req.body;

    const customer = await Customer.findByPk(customer_id);

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Update only provided fields
    const updateData = {};
    if (full_name !== undefined) updateData.full_name = full_name;
    if (phone !== undefined) updateData.phone = phone;
    if (profile_image_url !== undefined) updateData.profile_image_url = profile_image_url;

    await customer.update(updateData);

    // Fetch updated customer without password
    const updatedCustomer = await Customer.findByPk(customer_id, {
      attributes: { exclude: ['password_hash'] },
    });

    res.json({
      message: 'Profile updated successfully',
      user: updatedCustomer,
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Change customer password
 * PATCH /api/customers/password
 */
exports.changePassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const customer_id = req.user.id;
    const { current_password, new_password } = req.body;

    const customer = await Customer.findByPk(customer_id);

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Verify current password
    const isPasswordValid = await comparePassword(current_password, customer.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    // Hash new password and update
    const new_password_hash = await hashPassword(new_password);
    await customer.update({ password_hash: new_password_hash });

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
