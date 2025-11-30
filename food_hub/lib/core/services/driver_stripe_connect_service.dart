import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/constants/app_constants.dart';

class DriverStripeConnectService {
  static final DriverStripeConnectService _instance = DriverStripeConnectService._internal();
  factory DriverStripeConnectService() => _instance;
  DriverStripeConnectService._internal();

  /// Connect Accountを作成
  Future<Map<String, dynamic>> createAccount(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/stripe/connect/driver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      print('[DriverStripeConnect] Create account error: $e');
      rethrow;
    }
  }

  /// アカウント状態を取得
  Future<Map<String, dynamic>> getAccountStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/stripe/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get status');
      }
    } catch (e) {
      print('[DriverStripeConnect] Get status error: $e');
      rethrow;
    }
  }

  /// オンボーディングを開始
  Future<String> startOnboarding(String token) async {
    try {
      // アカウント作成
      final accountData = await createAccount(token);
      return accountData['onboarding_url'] as String;
    } catch (e) {
      print('[DriverStripeConnect] Start onboarding error: $e');
      rethrow;
    }
  }
}
