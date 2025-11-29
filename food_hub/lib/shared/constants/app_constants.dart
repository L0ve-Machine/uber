class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://133.117.77.23:3000/api';
  static const String socketUrl = 'http://133.117.77.23:3000';

  // Stripe Keys (Replace with your own keys)
  static const String stripePublishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY';

  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userTypeKey = 'user_type';
  static const String isLoggedInKey = 'is_logged_in';

  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeRestaurant = 'restaurant';
  static const String userTypeDriver = 'driver';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusAccepted = 'accepted';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusPickedUp = 'picked_up';
  static const String orderStatusDelivering = 'delivering';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Image Upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // Delivery
  static const double defaultDeliveryRadius = 10.0; // km
  static const double minOrderAmount = 500.0; // yen

  // Rating
  static const int maxRating = 5;
  static const int minRating = 1;
}
