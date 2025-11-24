-- FoodHub Database Schema
-- Database: foodhub
-- Version: 1.0

-- Create Database
CREATE DATABASE IF NOT EXISTS foodhub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE foodhub;

-- ============================================
-- CUSTOMERS (購入者)
-- ============================================
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ============================================
-- CUSTOMER ADDRESSES (配達先住所)
-- ============================================
CREATE TABLE customer_addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_line VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_default BOOLEAN DEFAULT FALSE,
    label VARCHAR(50) DEFAULT 'Home', -- 'Home', 'Work', 'Other'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer_id (customer_id),
    INDEX idx_is_default (is_default)
) ENGINE=InnoDB;

-- ============================================
-- RESTAURANTS (レストラン)
-- ============================================
CREATE TABLE restaurants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL, -- 'Japanese', 'Chinese', 'Italian', etc.
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    cover_image_url TEXT,
    logo_url TEXT,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INT DEFAULT 0,
    min_order_amount DECIMAL(10,2) DEFAULT 0.00,
    delivery_fee DECIMAL(10,2) DEFAULT 0.00,
    delivery_time_minutes INT DEFAULT 30,
    delivery_radius_km DECIMAL(5,2) DEFAULT 5.00,
    is_open BOOLEAN DEFAULT TRUE,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_category (category),
    INDEX idx_is_open (is_open),
    INDEX idx_rating (rating),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB;

-- ============================================
-- RESTAURANT HOURS (営業時間)
-- ============================================
CREATE TABLE restaurant_hours (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    day_of_week TINYINT NOT NULL, -- 0=Monday, 6=Sunday
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    INDEX idx_restaurant_day (restaurant_id, day_of_week)
) ENGINE=InnoDB;

-- ============================================
-- MENU ITEMS (メニュー)
-- ============================================
CREATE TABLE menu_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Appetizer', 'Main', 'Dessert', etc.
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_category (category),
    INDEX idx_is_available (is_available)
) ENGINE=InnoDB;

-- ============================================
-- MENU ITEM OPTIONS (オプション)
-- ============================================
CREATE TABLE menu_item_options (
    id INT AUTO_INCREMENT PRIMARY KEY,
    menu_item_id INT NOT NULL,
    option_group_name VARCHAR(100) NOT NULL, -- 'Size', 'Toppings', etc.
    option_name VARCHAR(100) NOT NULL,
    additional_price DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE,
    INDEX idx_menu_item_id (menu_item_id)
) ENGINE=InnoDB;

-- ============================================
-- DRIVERS (配達員)
-- ============================================
CREATE TABLE drivers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL, -- 'Motorcycle', 'Bicycle', 'Car'
    license_number VARCHAR(100),
    profile_image_url TEXT,
    is_online BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_approved BOOLEAN DEFAULT FALSE,
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_deliveries INT DEFAULT 0,
    bank_account_info JSON, -- { "bank_name": "...", "account_number": "..." }
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_is_online (is_online),
    INDEX idx_rating (rating)
) ENGINE=InnoDB;

-- ============================================
-- ORDERS (注文)
-- ============================================
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(20) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,
    delivery_address_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled') DEFAULT 'pending',
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    tax DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0.00,
    total DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- 'card', 'cash'
    stripe_payment_id VARCHAR(255),
    special_instructions TEXT,
    scheduled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    picked_up_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    FOREIGN KEY (delivery_address_id) REFERENCES customer_addresses(id),
    INDEX idx_order_number (order_number),
    INDEX idx_customer_id (customer_id),
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ============================================
-- ORDER ITEMS (注文明細)
-- ============================================
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    menu_item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    selected_options JSON, -- [{"group": "Size", "name": "Large", "price": 200}]
    special_request TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id),
    INDEX idx_order_id (order_id)
) ENGINE=InnoDB;

-- ============================================
-- REVIEWS (レビュー)
-- ============================================
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    driver_id INT,
    restaurant_rating TINYINT CHECK (restaurant_rating BETWEEN 1 AND 5),
    driver_rating TINYINT CHECK (driver_rating BETWEEN 1 AND 5),
    comment TEXT,
    images JSON, -- ["url1", "url2"]
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id),
    FOREIGN KEY (driver_id) REFERENCES drivers(id),
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_driver_id (driver_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- ============================================
-- FAVORITES (お気に入り)
-- ============================================
CREATE TABLE favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    UNIQUE KEY unique_favorite (customer_id, restaurant_id),
    INDEX idx_customer_id (customer_id)
) ENGINE=InnoDB;

-- ============================================
-- Initial Data (テスト用データ)
-- ============================================

-- Test Customer
INSERT INTO customers (email, password_hash, full_name, phone) VALUES
('customer@test.com', '$2b$10$abcdefghijklmnopqrstuvwxyz1234567890', 'Test Customer', '080-1234-5678');

-- Test Restaurant
INSERT INTO restaurants (email, password_hash, name, description, category, phone, address, latitude, longitude, is_approved) VALUES
('restaurant@test.com', '$2b$10$abcdefghijklmnopqrstuvwxyz1234567890', 'Test Restaurant', 'Delicious Japanese food', 'Japanese', '03-1234-5678', 'Tokyo, Shibuya', 35.6581, 139.7017, TRUE);

-- Test Driver
INSERT INTO drivers (email, password_hash, full_name, phone, vehicle_type, is_approved) VALUES
('driver@test.com', '$2b$10$abcdefghijklmnopqrstuvwxyz1234567890', 'Test Driver', '090-1234-5678', 'Motorcycle', TRUE);
