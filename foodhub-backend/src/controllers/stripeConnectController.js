const stripe = require('../config/stripe');
const Restaurant = require('../models/Restaurant');
const Driver = require('../models/Driver');

/**
 * Create Stripe Connect account for restaurant
 * POST /api/restaurant/stripe/connect
 */
exports.createRestaurantAccount = async (req, res) => {
  try {
    const restaurant_id = req.user.id;
    const restaurant = await Restaurant.findByPk(restaurant_id);

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found' });
    }

    // Check if account already exists
    if (restaurant.stripe_account_id) {
      return res.status(400).json({
        error: 'Stripe account already exists',
        account_id: restaurant.stripe_account_id,
      });
    }

    // Create Stripe Connected Account
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'JP',
      email: restaurant.email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_type: 'company',
      business_profile: {
        name: restaurant.name,
        product_description: 'Restaurant food service',
      },
    });

    // Save to database
    await restaurant.update({
      stripe_account_id: account.id,
    });

    // Create onboarding link
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/restaurant/stripe/refresh`,
      return_url: `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/restaurant/stripe/return`,
      type: 'account_onboarding',
    });

    res.json({
      account_id: account.id,
      onboarding_url: accountLink.url,
      message: 'Please complete Stripe onboarding',
    });
  } catch (error) {
    console.error('Create restaurant Stripe account error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
};

/**
 * Create Stripe Connect account for driver
 * POST /api/driver/stripe/connect
 */
exports.createDriverAccount = async (req, res) => {
  try {
    const driver_id = req.user.id;
    const driver = await Driver.findByPk(driver_id);

    if (!driver) {
      return res.status(404).json({ error: 'Driver not found' });
    }

    if (driver.stripe_account_id) {
      return res.status(400).json({
        error: 'Stripe account already exists',
        account_id: driver.stripe_account_id,
      });
    }

    // Create Stripe Connected Account
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'JP',
      email: driver.email,
      capabilities: {
        transfers: { requested: true },
      },
      business_type: 'individual',
    });

    // Save to database
    await driver.update({
      stripe_account_id: account.id,
    });

    // Create onboarding link
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/driver/stripe/refresh`,
      return_url: `${process.env.APP_URL || 'https://133-117-77-23.nip.io'}/driver/stripe/return`,
      type: 'account_onboarding',
    });

    res.json({
      account_id: account.id,
      onboarding_url: accountLink.url,
      message: 'Please complete Stripe onboarding',
    });
  } catch (error) {
    console.error('Create driver Stripe account error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
};

/**
 * Handle Stripe Connect webhook events
 * POST /webhook/stripe/connect
 */
exports.handleConnectWebhook = async (req, res) => {
  try {
    const sig = req.headers['stripe-signature'];
    const event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_CONNECT_WEBHOOK_SECRET
    );

    console.log(`[Stripe Webhook] Received: ${event.type}`);

    if (event.type === 'account.updated') {
      const account = event.data.object;

      // Update restaurant or driver
      const restaurant = await Restaurant.findOne({
        where: { stripe_account_id: account.id },
      });

      if (restaurant) {
        await restaurant.update({
          stripe_onboarding_completed: account.details_submitted,
          stripe_charges_enabled: account.charges_enabled,
          stripe_payouts_enabled: account.payouts_enabled,
        });
        console.log(`[Stripe Webhook] Restaurant ${restaurant.id} updated`);
      }

      const driver = await Driver.findOne({
        where: { stripe_account_id: account.id },
      });

      if (driver) {
        await driver.update({
          stripe_onboarding_completed: account.details_submitted,
          stripe_payouts_enabled: account.payouts_enabled,
        });
        console.log(`[Stripe Webhook] Driver ${driver.id} updated`);
      }
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Stripe webhook error:', error);
    res.status(400).json({ error: 'Webhook error' });
  }
};

/**
 * Get Stripe account status
 * GET /api/restaurant/stripe/status (for restaurant)
 * GET /api/driver/stripe/status (for driver)
 */
exports.getAccountStatus = async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.user_type;

    let user;
    if (userType === 'restaurant') {
      user = await Restaurant.findByPk(userId);
    } else if (userType === 'driver') {
      user = await Driver.findByPk(userId);
    }

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      stripe_account_id: user.stripe_account_id,
      stripe_onboarding_completed: user.stripe_onboarding_completed,
      stripe_charges_enabled: user.stripe_charges_enabled || false,
      stripe_payouts_enabled: user.stripe_payouts_enabled || false,
    });
  } catch (error) {
    console.error('Get account status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
