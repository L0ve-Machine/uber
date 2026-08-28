const { verifyToken } = require('../utils/jwt');
const { isTokenRevoked } = require('../utils/tokenDenylist');
const { audit, clientIp } = require('../utils/audit');

/**
 * 403 (権限不足) を監査ログに残してからレスポンスを返す (ASVS V7.2)
 */
const denyRole = (req, res, requiredRole) => {
  audit('authz.denied', {
    actor_type: req.user?.user_type,
    actor_id: req.user?.id,
    required_role: requiredRole,
    method: req.method,
    path: req.originalUrl,
    ip: clientIp(req),
    result: 'denied',
  });
  return res
    .status(403)
    .json({ error: `Access denied. ${requiredRole} only.` });
};

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

    // ログアウト済みトークンを拒否する (ASVS V3.3)
    if (isTokenRevoked(decoded.jti)) {
      audit('auth.token.revoked_use', {
        actor_type: decoded.user_type,
        actor_id: decoded.id,
        path: req.originalUrl,
        ip: clientIp(req),
        result: 'denied',
      });
      return res.status(401).json({ error: 'Token has been revoked' });
    }

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
    return denyRole(req, res, 'Customer');
  }
  next();
};

/**
 * Check if user is a restaurant
 */
const isRestaurant = (req, res, next) => {
  if (req.user.user_type !== 'restaurant') {
    return denyRole(req, res, 'Restaurant');
  }
  next();
};

/**
 * Check if user is a driver
 */
const isDriver = (req, res, next) => {
  if (req.user.user_type !== 'driver') {
    return denyRole(req, res, 'Driver');
  }
  next();
};

module.exports = {
  authMiddleware,
  isCustomer,
  isRestaurant,
  isDriver,
};
