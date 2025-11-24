const { verifyToken } = require('../utils/jwt');

/**
 * Authentication middleware
 * Verifies JWT token and attaches user info to request
 */
const authMiddleware = (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const decoded = verifyToken(token);

    // Attach user info to request
    req.user = decoded;

    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

/**
 * Check if user is a customer
 */
const isCustomer = (req, res, next) => {
  if (req.user.user_type !== 'customer') {
    return res.status(403).json({ error: 'Access denied. Customer only.' });
  }
  next();
};

/**
 * Check if user is a restaurant
 */
const isRestaurant = (req, res, next) => {
  if (req.user.user_type !== 'restaurant') {
    return res.status(403).json({ error: 'Access denied. Restaurant only.' });
  }
  next();
};

/**
 * Check if user is a driver
 */
const isDriver = (req, res, next) => {
  if (req.user.user_type !== 'driver') {
    return res.status(403).json({ error: 'Access denied. Driver only.' });
  }
  next();
};

module.exports = {
  authMiddleware,
  isCustomer,
  isRestaurant,
  isDriver,
};
