require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');
const sequelize = require('./config/database');
const { verifyToken } = require('./utils/jwt');
const { isTokenRevoked } = require('./utils/tokenDenylist');
const { audit } = require('./utils/audit');

// Initialize model associations
require('./models/index');

/**
 * CORS / Socket.IO の許可オリジン (ASVS V13.1)
 * ALLOWED_ORIGINS にカンマ区切りで列挙する。未設定なら APP_URL のみを許可。
 * クライアントは Flutter ネイティブなので、ブラウザ由来のオリジンは実質不要。
 */
const allowedOrigins = (process.env.ALLOWED_ORIGINS || process.env.APP_URL || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

/**
 * CORS のオリジン判定。
 * Origin ヘッダが無いリクエスト (Flutter ネイティブ・curl・Stripe からの Webhook) は
 * ブラウザの同一オリジンポリシーの対象外なので許可する。
 * ブラウザから来た未登録オリジンだけを拒否する。
 */
const corsOriginCheck = (origin, callback) => {
  if (!origin) return callback(null, true);
  if (allowedOrigins.includes(origin)) return callback(null, true);
  return callback(new Error('Not allowed by CORS'));
};

const app = express();

// ホスト nginx (133-117-77-23.nip.io) → localhost:3000 の 1 ホップ構成。
// X-Forwarded-For の最終ホップだけを信頼する。レート制限と監査ログの
// クライアント IP がこの設定に依存するため、経路構成を変えたら必ず見直すこと。
app.set('trust proxy', 1);

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    // HTTP 側と同じ許可リストを使う (ASVS V13.1)
    origin: allowedOrigins,
    methods: ['GET', 'POST'],
    credentials: false,
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
// helmet でセキュリティヘッダを付与する (ASVS V14.1)
// contentSecurityPolicy は無効化している: 本 API は JSON を返すのが主で、
// HTML を返すのは Stripe オンボーディング復帰用の固定ページのみ。
// 不用意な CSP はそれらの表示を壊す割にここでは得るものが少ないため、
// まず他のヘッダ (X-Content-Type-Options / X-Frame-Options / Referrer-Policy 等) を確実に効かせる。
// HTML ページを本格的に増やす場合は CSP を設計したうえで有効化すること。
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: corsOriginCheck, credentials: false }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Static files - serve uploaded images
// メニュー画像は別オリジンから <img> で読まれる可能性があるため、
// helmet 既定の Cross-Origin-Resource-Policy: same-origin をこのパスだけ緩める。
app.use(
  '/uploads',
  (req, res, next) => {
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    next();
  },
  express.static(path.join(__dirname, '../uploads'))
);

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
app.use('/api/upload', require('./routes/upload')); // Image uploads

// Error handling middleware
app.use((err, req, res, next) => {
  // サーバー側には従来どおり詳細を残す (調査に必要)
  console.error(err.stack);

  // CORS 拒否は 500 ではなく 403 で返す
  if (err && err.message === 'Not allowed by CORS') {
    return res.status(403).json({ error: 'Origin not allowed' });
  }

  // クライアントには開発環境以外で内部情報を返さない (ASVS V7.1)
  const isDevelopment = process.env.NODE_ENV === 'development';
  res.status(500).json({
    error: 'Something went wrong!',
    message: isDevelopment ? err.message : undefined,
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
const Order = require('./models/Order');

// Store active driver connections
const activeDrivers = new Map(); // driverId -> socketId

/**
 * Socket.IO ハンドシェイク認証 (ASVS V4.1)
 *
 * 従来は誰でも接続でき、driver:location-update の driverId もクライアント任せだった。
 * ここで JWT を検証し、以降のイベントでは socket.user のみを信頼する。
 *
 * クライアントは接続時に auth でトークンを渡すこと:
 *   IO.OptionBuilder().setAuth({'token': jwt})
 * 互換のため Authorization ヘッダも受け付ける。
 */
io.use((socket, next) => {
  const headerToken = socket.handshake.headers && socket.handshake.headers.authorization;
  const token =
    (socket.handshake.auth && socket.handshake.auth.token) ||
    (typeof headerToken === 'string'
      ? headerToken.replace(/^Bearer /i, '')
      : undefined);

  if (!token) {
    audit('socket.connect', { result: 'denied', reason: 'no_token' });
    return next(new Error('unauthorized'));
  }

  try {
    const decoded = verifyToken(token);

    // ログアウト済みトークンでの接続を拒否する (ASVS V3.3)
    if (isTokenRevoked(decoded.jti)) {
      audit('socket.connect', {
        actor_type: decoded.user_type,
        actor_id: decoded.id,
        result: 'denied',
        reason: 'revoked_token',
      });
      return next(new Error('unauthorized'));
    }

    socket.user = decoded;
    return next();
  } catch (error) {
    audit('socket.connect', { result: 'denied', reason: 'invalid_token' });
    return next(new Error('unauthorized'));
  }
});

io.on('connection', (socket) => {
  const user = socket.user;
  audit('socket.connect', {
    actor_type: user.user_type,
    actor_id: user.id,
    result: 'success',
  });

  // 自分専用のルームに入れておく (個別通知用)
  socket.join(`${user.user_type}-${user.id}`);

  // Driver connects and registers
  socket.on('driver:register', async (data) => {
    // クライアントが送ってくる driverId は信用しない。トークン由来の ID のみを使う。
    if (user.user_type !== 'driver') {
      return socket.emit('driver:registered', {
        success: false,
        error: 'forbidden',
      });
    }

    const driverId = user.id;
    activeDrivers.set(driverId, socket.id);
    socket.driverId = driverId;
    socket.join(`driver-${driverId}`);

    socket.emit('driver:registered', { success: true });
  });

  /**
   * 顧客が自分の注文の配達追跡ルームに参加する
   * 位置情報を全接続へブロードキャストせず、当該注文の関係者だけに配るために必要。
   * 注文の所有者であることをサーバー側で確認してからルームに入れる。
   */
  socket.on('customer:track-order', async (data, ack) => {
    try {
      if (user.user_type !== 'customer') {
        if (typeof ack === 'function') ack({ success: false, error: 'forbidden' });
        return;
      }

      const orderId = parseInt(data && data.orderId, 10);
      if (!Number.isInteger(orderId)) {
        if (typeof ack === 'function') ack({ success: false, error: 'invalid_order' });
        return;
      }

      const order = await Order.findOne({
        where: { id: orderId, customer_id: user.id },
        attributes: ['id'],
      });

      if (!order) {
        audit('socket.track_order', {
          actor_type: 'customer',
          actor_id: user.id,
          target_id: orderId,
          result: 'denied',
        });
        if (typeof ack === 'function') ack({ success: false, error: 'not_found' });
        return;
      }

      socket.join(`order-${orderId}`);
      if (typeof ack === 'function') ack({ success: true });
    } catch (error) {
      console.error('Error joining order room:', error);
      if (typeof ack === 'function') ack({ success: false, error: 'server_error' });
    }
  });

  /** 追跡ルームから抜ける */
  socket.on('customer:untrack-order', (data) => {
    const orderId = parseInt(data && data.orderId, 10);
    if (Number.isInteger(orderId)) {
      socket.leave(`order-${orderId}`);
    }
  });

  // Driver sends location update
  socket.on('driver:location-update', async (data) => {
    // 位置を書き換えられるのは「そのトークンの配達員自身」だけ (ASVS V4.2)
    if (user.user_type !== 'driver') {
      audit('driver.location.update', {
        actor_type: user.user_type,
        actor_id: user.id,
        result: 'denied',
        reason: 'not_a_driver',
      });
      return;
    }

    // driverId はクライアント送信値ではなく JWT から取る
    const driverId = user.id;
    const latitude = Number(data && data.latitude);
    const longitude = Number(data && data.longitude);

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return;
    }

    try {
      // Update driver location in database (正確な位置を保存)
      await Driver.update(
        {
          current_latitude: latitude,
          current_longitude: longitude,
        },
        { where: { id: driverId } }
      );

      // 座標そのものは個人情報なのでログには残さない

      // ===== Privacy: ぼかし処理 (200m範囲でランダム化) =====
      const BLUR_RADIUS_METERS = 200;

      // 緯度のオフセット (1度 ≈ 111km)
      const latOffset = (Math.random() - 0.5) * (BLUR_RADIUS_METERS / 111000);

      // 経度のオフセット (緯度による補正)
      const lngOffset = (Math.random() - 0.5) * (BLUR_RADIUS_METERS / (111000 * Math.cos(latitude * Math.PI / 180)));

      const blurredLat = latitude + latOffset;
      const blurredLng = longitude + lngOffset;

      const payload = {
        driverId,
        latitude: blurredLat,
        longitude: blurredLng,
        timestamp: new Date().toISOString(),
      };

      // 全接続へのブロードキャスト (io.emit) をやめ、関係者のルームだけに配る。
      // 送り先: ①配達員自身 ②その配達員が担当中の注文を追跡している顧客
      // 対象注文が無ければ誰にも配られない (以前は全接続へ漏れていた)。
      const activeOrders = await Order.findAll({
        where: {
          driver_id: driverId,
          status: ['ready', 'picked_up', 'delivering'],
        },
        attributes: ['id'],
      });

      const rooms = [
        `driver-${driverId}`,
        ...activeOrders.map((order) => `order-${order.id}`),
      ];

      io.to(rooms).emit('driver:location-changed', payload);
    } catch (error) {
      console.error('Error updating driver location:', error);
    }
  });

  // Disconnect
  socket.on('disconnect', () => {
    if (socket.driverId) {
      activeDrivers.delete(socket.driverId);
    }
    audit('socket.disconnect', {
      actor_type: user.user_type,
      actor_id: user.id,
      result: 'success',
    });
  });
});

// Make io accessible to routes
app.set('io', io);

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Also accessible on http://0.0.0.0:${PORT}`);
  console.log(`Socket.IO server ready`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});

module.exports = { app, server, io };
