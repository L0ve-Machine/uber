import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/customer/screens/home_screen.dart';
import 'features/customer/screens/restaurant_detail_screen.dart';
import 'features/customer/screens/cart_screen.dart';
import 'features/customer/screens/order_history_screen.dart';
import 'features/customer/screens/order_detail_screen.dart';
import 'features/customer/screens/checkout_screen.dart';
import 'features/customer/screens/order_confirmation_screen.dart';
import 'features/customer/screens/order_tracking_screen.dart';
import 'features/customer/screens/address_selection_screen.dart';
import 'features/customer/screens/add_address_screen.dart';
import 'features/restaurant/screens/restaurant_dashboard_screen.dart';
import 'features/restaurant/screens/restaurant_menu_add_screen.dart';
import 'features/driver/screens/driver_dashboard_screen.dart';
import 'shared/constants/app_constants.dart';
import 'shared/models/address_model.dart';
import 'shared/models/order_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'FoodHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        // Customer routes
        AppRoutes.customerHome: (context) => const HomeScreen(),
        // Restaurant routes
        '/restaurant/dashboard': (context) => const RestaurantDashboardScreen(),
        '/restaurant/menu/add': (context) => const RestaurantMenuAddScreen(),
        // Driver routes
        '/driver/dashboard': (context) => const DriverDashboardScreen(),
      },
onGenerateRoute: (settings) {
        // Handle restaurant detail route with parameter
        if (settings.name == '/customer/restaurant') {
          final restaurantId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => RestaurantDetailScreen(restaurantId: restaurantId),
          );
        }
        // Handle cart route
        if (settings.name == '/customer/cart') {
          return MaterialPageRoute(
            builder: (context) => const CartScreen(),
          );
        }
        // Handle order history route
        if (settings.name == '/customer/order-history') {
          return MaterialPageRoute(
            builder: (context) => const OrderHistoryScreen(),
          );
        }
        // Handle order detail route with parameter
        if (settings.name == '/customer/order-detail') {
          final orderId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
          );
        }
        // Handle checkout route
        if (settings.name == '/customer/checkout') {
          return MaterialPageRoute(
            builder: (context) => const CheckoutScreen(),
          );
        }
        // Handle order confirmation route
        if (settings.name == '/customer/order-confirmation') {
          final order = settings.arguments as OrderModel;
          return MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          );
        }
        // Handle order tracking route
        if (settings.name != null && settings.name!.startsWith('/customer/order-tracking/')) {
          final orderId = int.parse(settings.name!.split('/').last);
          return MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(orderId: orderId),
          );
        }
        // Handle address selection route
        if (settings.name == '/customer/addresses/select') {
          final currentAddress = settings.arguments as AddressModel?;
          return MaterialPageRoute(
            builder: (context) => AddressSelectionScreen(currentAddress: currentAddress),
          );
        }
        // Handle add address route
        if (settings.name == '/customer/addresses/add') {
          return MaterialPageRoute(
            builder: (context) => const AddAddressScreen(),
          );
        }
        return null;
      },
    );
  }
}


// Splash Screen with auto-navigation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is logged in
    final storageService = ref.read(storageServiceProvider);
    final isLoggedIn = await storageService.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Get user type and navigate to appropriate dashboard
      final userType = await storageService.getUserType();

      if (!mounted) return;

      switch (userType) {
        case AppConstants.userTypeCustomer:
          Navigator.of(context).pushReplacementNamed(AppRoutes.customerHome);
          break;
        case AppConstants.userTypeRestaurant:
          Navigator.of(context).pushReplacementNamed('/restaurant/dashboard');
          break;
        case AppConstants.userTypeDriver:
          Navigator.of(context).pushReplacementNamed('/driver/dashboard');
          break;
        default:
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } else {
      // Navigate to login
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'FoodHub',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'おいしい料理をあなたのもとへ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
