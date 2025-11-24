class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String selectUserType = '/select-user-type';

  // Customer Routes
  static const String customerHome = '/customer/home';
  static const String restaurantDetail = '/customer/restaurant/:id';
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';
  static const String orderTracking = '/customer/order-tracking/:id';
  static const String orderHistory = '/customer/order-history';
  static const String customerProfile = '/customer/profile';
  static const String addressManagement = '/customer/addresses';

  // Restaurant Routes
  static const String restaurantDashboard = '/restaurant/dashboard';
  static const String menuManagement = '/restaurant/menu';
  static const String addMenuItem = '/restaurant/menu/add';
  static const String editMenuItem = '/restaurant/menu/edit/:id';
  static const String orderManagement = '/restaurant/orders';
  static const String restaurantProfile = '/restaurant/profile';
  static const String salesReport = '/restaurant/sales';

  // Driver Routes
  static const String driverHome = '/driver/home';
  static const String deliveryRequest = '/driver/delivery-request/:id';
  static const String activeDelivery = '/driver/active-delivery/:id';
  static const String deliveryHistory = '/driver/history';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';
}
