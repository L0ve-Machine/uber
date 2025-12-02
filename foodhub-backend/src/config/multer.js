const multer = require('multer');
const path = require('path');

// Storage configuration for menu items
const menuItemStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/menu-items/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'menu-' + uniqueSuffix + path.extname(file.originalname));
  },
});

// Storage configuration for restaurants
const restaurantStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/restaurants/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'restaurant-' + uniqueSuffix + path.extname(file.originalname));
  },
});

// File filter - only images
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
  }
};

// Multer instances
const uploadMenuImages = multer({
  storage: menuItemStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max per file
  },
  fileFilter: fileFilter,
}).array('images', 10); // Max 10 images

const uploadRestaurantImages = multer({
  storage: restaurantStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max per file
  },
  fileFilter: fileFilter,
}).array('images', 5); // Max 5 images

module.exports = {
  uploadMenuImages,
  uploadRestaurantImages,
};
