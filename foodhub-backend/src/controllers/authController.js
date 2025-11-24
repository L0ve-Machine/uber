const { validationResult } = require('express-validator');
const Customer = require('../models/Customer');
const Restaurant = require('../models/Restaurant');
const Driver = require('../models/Driver');
const { hashPassword, comparePassword } = require('../utils/password');
const { generateToken } = require('../utils/jwt');

/**
 * Login
 * POST /api/auth/login
 */
exports.login = async (req, res) => {
  try {
    // Validation
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, user_type } = req.body;

    // Determine which model to use based on user_type
    let UserModel;
    switch (user_type) {
      case 'customer':
        UserModel = Customer;
        break;
      case 'restaurant':
        UserModel = Restaurant;
        break;
      case 'driver':
        UserModel = Driver;
        break;
      default:
        return res.status(400).json({ error: 'Invalid user type' });
    }

    // Find user by email
    const user = await UserModel.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if user is active (for customers and drivers)
    if (user.is_active === false) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    // Check if approved (for restaurants and drivers)
    if ((user_type === 'restaurant' || user_type === 'driver') && !user.is_approved) {
      return res.status(403).json({ error: 'Account pending approval' });
    }

    // Compare password
    const isPasswordValid = await comparePassword(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = generateToken({
      id: user.id,
      email: user.email,
      user_type,
    });

    // Prepare user data (exclude password_hash)
    const userData = user.toJSON();
    delete userData.password_hash;

    // Send response
    res.json({
      message: 'Login successful',
      token,
      user: userData,
      user_type,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Register Customer
 * POST /api/auth/register/customer
 */
exports.registerCustomer = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, full_name, phone } = req.body;

    // Check if email already exists
    const existingCustomer = await Customer.findOne({ where: { email } });
    if (existingCustomer) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const password_hash = await hashPassword(password);

    // Create customer
    const customer = await Customer.create({
      email,
      password_hash,
      full_name,
      phone,
    });

    // Generate token
    const token = generateToken({
      id: customer.id,
      email: customer.email,
      user_type: 'customer',
    });

    // Prepare response
    const userData = customer.toJSON();
    delete userData.password_hash;

    res.status(201).json({
      message: 'Customer registered successfully',
      token,
      user: userData,
      user_type: 'customer',
    });
  } catch (error) {
    console.error('Register customer error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Register Restaurant
 * POST /api/auth/register/restaurant
 */
exports.registerRestaurant = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      email,
      password,
      name,
      description,
      category,
      phone,
      address,
      latitude,
      longitude,
    } = req.body;

    // Check if email already exists
    const existingRestaurant = await Restaurant.findOne({ where: { email } });
    if (existingRestaurant) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const password_hash = await hashPassword(password);

    // Create restaurant
    const restaurant = await Restaurant.create({
      email,
      password_hash,
      name,
      description,
      category,
      phone,
      address,
      latitude,
      longitude,
      is_approved: false, // Requires admin approval
    });

    // Generate token
    const token = generateToken({
      id: restaurant.id,
      email: restaurant.email,
      user_type: 'restaurant',
    });

    // Prepare response
    const userData = restaurant.toJSON();
    delete userData.password_hash;

    res.status(201).json({
      message: 'Restaurant registered successfully. Pending approval.',
      token,
      user: userData,
      user_type: 'restaurant',
    });
  } catch (error) {
    console.error('Register restaurant error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Register Driver
 * POST /api/auth/register/driver
 */
exports.registerDriver = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      email,
      password,
      full_name,
      phone,
      vehicle_type,
      license_number,
    } = req.body;

    // Check if email already exists
    const existingDriver = await Driver.findOne({ where: { email } });
    if (existingDriver) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // Hash password
    const password_hash = await hashPassword(password);

    // Create driver
    const driver = await Driver.create({
      email,
      password_hash,
      full_name,
      phone,
      vehicle_type,
      license_number,
      is_approved: false, // Requires admin approval
    });

    // Generate token
    const token = generateToken({
      id: driver.id,
      email: driver.email,
      user_type: 'driver',
    });

    // Prepare response
    const userData = driver.toJSON();
    delete userData.password_hash;

    res.status(201).json({
      message: 'Driver registered successfully. Pending approval.',
      token,
      user: userData,
      user_type: 'driver',
    });
  } catch (error) {
    console.error('Register driver error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

/**
 * Get current user
 * GET /api/auth/me
 */
exports.getCurrentUser = async (req, res) => {
  try {
    // User info is attached by auth middleware
    const { id, user_type } = req.user;

    let UserModel;
    switch (user_type) {
      case 'customer':
        UserModel = Customer;
        break;
      case 'restaurant':
        UserModel = Restaurant;
        break;
      case 'driver':
        UserModel = Driver;
        break;
      default:
        return res.status(400).json({ error: 'Invalid user type' });
    }

    const user = await UserModel.findByPk(id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = user.toJSON();
    delete userData.password_hash;

    res.json({
      user: userData,
      user_type,
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
