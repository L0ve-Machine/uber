import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../../shared/constants/app_constants.dart';

class StripePaymentService {
  static final StripePaymentService _instance = StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  final Dio _dio = Dio();

  /// Stripeを初期化
  Future<void> initialize() async {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    print('[Stripe] Initialized with key: ${AppConstants.stripePublishableKey.substring(0, 20)}...');
  }

  /// Payment Intentを作成
  Future<Map<String, dynamic>> createPaymentIntent(int orderId, String token) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseUrl}/orders/$orderId/create-payment-intent',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      print('[Stripe] Create payment intent error: $e');
      rethrow;
    }
  }

  /// 決済処理を実行（Payment Sheet使用）
  Future<bool> processPayment({
    required int orderId,
    required String token,
  }) async {
    try {
      print('[Stripe] Processing payment for order: $orderId');

      // 1. Payment Intent作成
      final paymentData = await createPaymentIntent(orderId, token);
      final clientSecret = paymentData['client_secret'] as String;

      print('[Stripe] Client secret received');

      // 2. Payment Sheet初期化
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'FoodHub',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF000000),  // Black theme
            ),
          ),
        ),
      );

      print('[Stripe] Payment sheet initialized');

      // 3. Payment Sheet表示
      await Stripe.instance.presentPaymentSheet();

      print('[Stripe] Payment successful');
      return true;

    } on StripeException catch (e) {
      print('[Stripe] Payment failed: ${e.error.message}');

      // User cancelled
      if (e.error.code == FailureCode.Canceled) {
        print('[Stripe] Payment cancelled by user');
        return false;
      }

      rethrow;
    } catch (e) {
      print('[Stripe] Unexpected error: $e');
      rethrow;
    }
  }
}
