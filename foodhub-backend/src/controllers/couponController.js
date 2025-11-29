const { Coupon, CouponUsage } = require('../models');
const { validationResult } = require('express-validator');
const { Op } = require('sequelize');

// Validate a coupon code
exports.validateCoupon = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg,
      });
    }

    const customerId = req.user.id;
    const { code, subtotal } = req.body;

    // Find coupon by code
    const coupon = await Coupon.findOne({
      where: {
        code: code.toUpperCase(),
        is_active: true,
      },
    });

    if (!coupon) {
      return res.status(404).json({
        success: false,
        message: '無効なクーポンコードです',
      });
    }

    // Check if coupon is within valid date range
    const now = new Date();
    if (coupon.start_date && now < new Date(coupon.start_date)) {
      return res.status(400).json({
        success: false,
        message: 'このクーポンはまだ有効期間外です',
      });
    }
    if (coupon.end_date && now > new Date(coupon.end_date)) {
      return res.status(400).json({
        success: false,
        message: 'このクーポンは有効期限が切れています',
      });
    }

    // Check minimum order amount
    if (subtotal < parseFloat(coupon.min_order_amount)) {
      return res.status(400).json({
        success: false,
        message: `このクーポンは¥${parseInt(coupon.min_order_amount)}以上の注文で使用できます`,
      });
    }

    // Check total usage limit
    if (coupon.usage_limit) {
      const totalUsages = await CouponUsage.count({
        where: { coupon_id: coupon.id },
      });
      if (totalUsages >= coupon.usage_limit) {
        return res.status(400).json({
          success: false,
          message: 'このクーポンは使用回数の上限に達しました',
        });
      }
    }

    // Check per-user usage limit
    const userUsages = await CouponUsage.count({
      where: {
        coupon_id: coupon.id,
        customer_id: customerId,
      },
    });
    if (userUsages >= coupon.per_user_limit) {
      return res.status(400).json({
        success: false,
        message: 'このクーポンは既に使用済みです',
      });
    }

    // Calculate discount
    let discount = 0;
    if (coupon.discount_type === 'percent') {
      discount = subtotal * (parseFloat(coupon.discount_value) / 100);
      // Apply max discount if set
      if (coupon.max_discount && discount > parseFloat(coupon.max_discount)) {
        discount = parseFloat(coupon.max_discount);
      }
    } else {
      // Fixed discount
      discount = parseFloat(coupon.discount_value);
      // Don't exceed subtotal
      if (discount > subtotal) {
        discount = subtotal;
      }
    }

    res.json({
      success: true,
      message: 'クーポンが適用されました',
      data: {
        coupon: {
          id: coupon.id,
          code: coupon.code,
          discount_type: coupon.discount_type,
          discount_value: parseFloat(coupon.discount_value),
          min_order_amount: parseFloat(coupon.min_order_amount),
          max_discount: coupon.max_discount ? parseFloat(coupon.max_discount) : null,
        },
        discount: Math.floor(discount), // Round down to integer
      },
    });
  } catch (error) {
    console.error('Validate coupon error:', error);
    res.status(500).json({
      success: false,
      message: 'クーポンの検証に失敗しました',
    });
  }
};

// Get available coupons for customer
exports.getAvailableCoupons = async (req, res) => {
  try {
    const customerId = req.user.id;
    const now = new Date();

    // Get all active coupons within date range
    const coupons = await Coupon.findAll({
      where: {
        is_active: true,
        [Op.or]: [
          { start_date: null },
          { start_date: { [Op.lte]: now } },
        ],
        [Op.or]: [
          { end_date: null },
          { end_date: { [Op.gte]: now } },
        ],
      },
      order: [['created_at', 'DESC']],
    });

    // Filter out coupons that are fully used or already used by user
    const availableCoupons = [];
    for (const coupon of coupons) {
      // Check total usage
      if (coupon.usage_limit) {
        const totalUsages = await CouponUsage.count({
          where: { coupon_id: coupon.id },
        });
        if (totalUsages >= coupon.usage_limit) {
          continue;
        }
      }

      // Check user usage
      const userUsages = await CouponUsage.count({
        where: {
          coupon_id: coupon.id,
          customer_id: customerId,
        },
      });
      if (userUsages >= coupon.per_user_limit) {
        continue;
      }

      availableCoupons.push({
        id: coupon.id,
        code: coupon.code,
        discount_type: coupon.discount_type,
        discount_value: parseFloat(coupon.discount_value),
        min_order_amount: parseFloat(coupon.min_order_amount),
        max_discount: coupon.max_discount ? parseFloat(coupon.max_discount) : null,
        end_date: coupon.end_date,
      });
    }

    res.json({
      success: true,
      data: availableCoupons,
    });
  } catch (error) {
    console.error('Get available coupons error:', error);
    res.status(500).json({
      success: false,
      message: 'クーポンの取得に失敗しました',
    });
  }
};

// Record coupon usage (called when order is created)
exports.recordUsage = async (couponId, customerId, orderId, transaction) => {
  try {
    await CouponUsage.create({
      coupon_id: couponId,
      customer_id: customerId,
      order_id: orderId,
      used_at: new Date(),
    }, { transaction });
    return true;
  } catch (error) {
    console.error('Record coupon usage error:', error);
    return false;
  }
};
