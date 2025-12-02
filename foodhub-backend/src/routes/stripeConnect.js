const express = require('express');
const stripeConnectController = require('../controllers/stripeConnectController');
const { authMiddleware, isRestaurant, isDriver } = require('../middleware/auth');

const router = express.Router();

/**
 * @route   POST /api/stripe/connect/restaurant
 * @desc    Create Stripe Connect account for restaurant
 * @access  Private (Restaurant only)
 */
router.post(
  '/connect/restaurant',
  authMiddleware,
  isRestaurant,
  stripeConnectController.createRestaurantAccount
);

/**
 * @route   POST /api/stripe/connect/driver
 * @desc    Create Stripe Connect account for driver
 * @access  Private (Driver only)
 */
router.post(
  '/connect/driver',
  authMiddleware,
  isDriver,
  stripeConnectController.createDriverAccount
);

/**
 * @route   GET /api/stripe/status
 * @desc    Get Stripe account status
 * @access  Private (Restaurant or Driver)
 */
router.get('/status', authMiddleware, stripeConnectController.getAccountStatus);

/**
 * @route   POST /webhook/stripe/connect
 * @desc    Handle Stripe Connect webhook events
 * @access  Public (Stripe only)
 */
router.post('/webhook/connect', express.raw({ type: 'application/json' }), stripeConnectController.handleConnectWebhook);

/**
 * @route   GET /api/stripe/restaurant/return
 * @desc    Stripe onboarding return URL for restaurants
 * @access  Public
 */
router.get('/restaurant/return', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Stripe設定完了</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f6f9fc; }
          h1 { color: #32325d; }
          p { color: #525f7f; font-size: 18px; }
        </style>
      </head>
      <body>
        <h1>✅ Stripe設定が完了しました</h1>
        <p>アプリに戻って「状態を更新」ボタンを押してください</p>
        <p style="color: #aaa; font-size: 14px;">このウィンドウは閉じても構いません</p>
        <script>
          setTimeout(() => { try { window.close(); } catch(e) {} }, 5000);
        </script>
      </body>
    </html>
  `);
});

/**
 * @route   GET /api/stripe/restaurant/refresh
 * @desc    Stripe onboarding refresh URL for restaurants
 * @access  Public
 */
router.get('/restaurant/refresh', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Stripe設定更新中</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f6f9fc; }
          h1 { color: #32325d; }
        </style>
      </head>
      <body>
        <h1>🔄 Stripe設定を更新中...</h1>
        <p>しばらくお待ちください</p>
      </body>
    </html>
  `);
});

/**
 * @route   GET /api/stripe/driver/return
 * @desc    Stripe onboarding return URL for drivers
 * @access  Public
 */
router.get('/driver/return', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Stripe設定完了</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f6f9fc; }
          h1 { color: #32325d; }
          p { color: #525f7f; font-size: 18px; }
        </style>
      </head>
      <body>
        <h1>✅ Stripe設定が完了しました</h1>
        <p>アプリに戻って「状態を更新」ボタンを押してください</p>
        <p style="color: #aaa; font-size: 14px;">このウィンドウは閉じても構いません</p>
        <script>
          setTimeout(() => { try { window.close(); } catch(e) {} }, 5000);
        </script>
      </body>
    </html>
  `);
});

/**
 * @route   GET /api/stripe/driver/refresh
 * @desc    Stripe onboarding refresh URL for drivers
 * @access  Public
 */
router.get('/driver/refresh', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <title>Stripe設定更新中</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f6f9fc; }
          h1 { color: #32325d; }
        </style>
      </head>
      <body>
        <h1>🔄 Stripe設定を更新中...</h1>
        <p>しばらくお待ちください</p>
      </body>
    </html>
  `);
});

module.exports = router;
