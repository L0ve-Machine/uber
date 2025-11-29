-- Migration: Add delivery sequence support for multi-delivery batches
-- Date: 2025-11-29

USE foodhub;

-- Add delivery_sequence column to orders table
ALTER TABLE orders
ADD COLUMN delivery_sequence INT DEFAULT 1 AFTER driver_id,
ADD COLUMN estimated_delivery_time TIMESTAMP NULL AFTER scheduled_at;

-- Add index for efficient querying
CREATE INDEX idx_driver_sequence ON orders(driver_id, delivery_sequence, status);

-- Update existing orders to have delivery_sequence = 1
UPDATE orders SET delivery_sequence = 1 WHERE delivery_sequence IS NULL;

-- Add comment
ALTER TABLE orders
MODIFY COLUMN delivery_sequence INT DEFAULT 1 COMMENT 'Order sequence in driver batch (1=first delivery, 2=second, etc.)';
