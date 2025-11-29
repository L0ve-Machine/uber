const { Review, Customer, Restaurant, Order } = require('../models');
const { validationResult } = require('express-validator');

// Get reviews for a restaurant
exports.getRestaurantReviews = async (req, res) => {
  try {
    const { restaurantId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const offset = (page - 1) * limit;

    const { count, rows: reviews } = await Review.findAndCountAll({
      where: { restaurant_id: restaurantId },
      include: [
        {
          model: Customer,
          as: 'customer',
          attributes: ['id', 'full_name'],
        },
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    // Mask customer names (田中太郎 → 田中**)
    const maskedReviews = reviews.map(review => {
      const reviewJson = review.toJSON();
      if (reviewJson.customer && reviewJson.customer.full_name) {
        const name = reviewJson.customer.full_name;
        // Keep first character(s) and mask the rest
        const firstPart = name.length > 2 ? name.substring(0, 2) : name.substring(0, 1);
        reviewJson.customer.full_name = firstPart + '**';
      }
      return reviewJson;
    });

    // Calculate average rating
    const avgResult = await Review.findOne({
      where: { restaurant_id: restaurantId },
      attributes: [
        [Review.sequelize.fn('AVG', Review.sequelize.col('rating')), 'average_rating'],
        [Review.sequelize.fn('COUNT', Review.sequelize.col('id')), 'total_reviews'],
      ],
      raw: true,
    });

    res.json({
      success: true,
      data: {
        reviews: maskedReviews,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit),
        },
        stats: {
          averageRating: avgResult.average_rating ? parseFloat(avgResult.average_rating).toFixed(1) : null,
          totalReviews: parseInt(avgResult.total_reviews) || 0,
        },
      },
    });
  } catch (error) {
    console.error('Get restaurant reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'レビューの取得に失敗しました',
    });
  }
};

// Create a review
exports.createReview = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg,
      });
    }

    const customerId = req.user.id;
    const { order_id, rating, comment } = req.body;

    // Check if order exists and belongs to customer
    const order = await Order.findOne({
      where: {
        id: order_id,
        customer_id: customerId,
      },
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: '注文が見つかりません',
      });
    }

    // Check if order is delivered
    if (order.status !== 'delivered') {
      return res.status(400).json({
        success: false,
        message: '配達完了した注文のみレビューできます',
      });
    }

    // Check if review already exists for this order
    const existingReview = await Review.findOne({
      where: { order_id },
    });

    if (existingReview) {
      return res.status(400).json({
        success: false,
        message: 'この注文にはすでにレビューがあります',
      });
    }

    // Create review
    const review = await Review.create({
      customer_id: customerId,
      restaurant_id: order.restaurant_id,
      order_id,
      rating,
      comment: comment || null,
    });

    res.status(201).json({
      success: true,
      message: 'レビューを投稿しました',
      data: review,
    });
  } catch (error) {
    console.error('Create review error:', error);
    res.status(500).json({
      success: false,
      message: 'レビューの投稿に失敗しました',
    });
  }
};

// Get my reviews
exports.getMyReviews = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { page = 1, limit = 10 } = req.query;

    const offset = (page - 1) * limit;

    const { count, rows: reviews } = await Review.findAndCountAll({
      where: { customer_id: customerId },
      include: [
        {
          model: Restaurant,
          as: 'restaurant',
          attributes: ['id', 'name', 'image_url'],
        },
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    res.json({
      success: true,
      data: {
        reviews,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit),
        },
      },
    });
  } catch (error) {
    console.error('Get my reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'レビューの取得に失敗しました',
    });
  }
};

// Update a review
exports.updateReview = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg,
      });
    }

    const customerId = req.user.id;
    const { id } = req.params;
    const { rating, comment } = req.body;

    const review = await Review.findOne({
      where: {
        id,
        customer_id: customerId,
      },
    });

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'レビューが見つかりません',
      });
    }

    await review.update({
      rating,
      comment: comment || null,
    });

    res.json({
      success: true,
      message: 'レビューを更新しました',
      data: review,
    });
  } catch (error) {
    console.error('Update review error:', error);
    res.status(500).json({
      success: false,
      message: 'レビューの更新に失敗しました',
    });
  }
};

// Delete a review
exports.deleteReview = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { id } = req.params;

    const review = await Review.findOne({
      where: {
        id,
        customer_id: customerId,
      },
    });

    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'レビューが見つかりません',
      });
    }

    await review.destroy();

    res.json({
      success: true,
      message: 'レビューを削除しました',
    });
  } catch (error) {
    console.error('Delete review error:', error);
    res.status(500).json({
      success: false,
      message: 'レビューの削除に失敗しました',
    });
  }
};

// Check if order can be reviewed
exports.canReview = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { orderId } = req.params;

    const order = await Order.findOne({
      where: {
        id: orderId,
        customer_id: customerId,
      },
      include: [
        {
          model: Review,
          as: 'review',
        },
      ],
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: '注文が見つかりません',
      });
    }

    const canReview = order.status === 'delivered' && !order.review;

    res.json({
      success: true,
      data: {
        canReview,
        hasReview: !!order.review,
        review: order.review || null,
      },
    });
  } catch (error) {
    console.error('Can review check error:', error);
    res.status(500).json({
      success: false,
      message: 'エラーが発生しました',
    });
  }
};
