require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const sequelize = require('./config/database');

// Initialize model associations
require('./models/index');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*', // In production, specify allowed origins
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'FoodHub API is running',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.get('/api', (req, res) => {
  res.json({
    message: 'FoodHub API v1.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      customers: '/api/customers',
      restaurants: '/api/restaurants',
      drivers: '/api/drivers',
      orders: '/api/orders',
      reviews: '/api/reviews',
    },
  });
});

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/restaurants', require('./routes/restaurants'));
app.use('/api/menu-items', require('./routes/menuItems'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api', require('./routes/addresses')); // Handles /api/customers/:id/addresses & /api/addresses/:id
app.use('/api/favorites', require('./routes/favorites'));
app.use('/api/reviews', require('./routes/reviews')); // Review management
app.use('/api/coupons', require('./routes/coupons')); // Coupon management
app.use('/api/customers', require('./routes/customers')); // Customer profile management
app.use('/api/restaurant', require('./routes/restaurant')); // Restaurant dashboard & menu management
app.use('/api/driver', require('./routes/driver')); // Driver delivery management
app.use('/api/stripe', require('./routes/stripeConnect')); // Stripe Connect integration

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.originalUrl} not found`,
  });
});

// ==================== Socket.IO Setup ====================
const Driver = require('./models/Driver');

// Store active driver connections
const activeDrivers = new Map(); // driverId -> socketId

io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  // Driver connects and registers
  socket.on('driver:register', async (data) => {
    const { driverId, token } = data;
    console.log(`👤 Driver ${driverId} registered with socket ${socket.id}`);

    activeDrivers.set(driverId, socket.id);
    socket.driverId = driverId;
    socket.join(`driver-${driverId}`);

    socket.emit('driver:registered', { success: true });
  });

  // Driver sends location update
  socket.on('driver:location-update', async (data) => {
    const { driverId, latitude, longitude } = data;

    try {
      // Update driver location in database
      await Driver.update(
        {
          current_latitude: latitude,
          current_longitude: longitude,
        },
        { where: { id: driverId } }
      );

      console.log(`📍 Driver ${driverId} location updated: ${latitude}, ${longitude}`);

      // Broadcast to all customers tracking this driver
      io.emit('driver:location-changed', {
        driverId,
        latitude,
        longitude,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      console.error('Error updating driver location:', error);
    }
  });

  // Disconnect
  socket.on('disconnect', () => {
    if (socket.driverId) {
      activeDrivers.delete(socket.driverId);
      console.log(`👋 Driver ${socket.driverId} disconnected`);
    }
    console.log(`🔌 Client disconnected: ${socket.id}`);
  });
});

// Make io accessible to routes
app.set('io', io);

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🚀 Also accessible on http://0.0.0.0:${PORT}`);
  console.log(`🔌 Socket.IO server ready`);
  console.log(`📝 Environment: ${process.env.NODE_ENV}`);
});

module.exports = { app, server, io };
