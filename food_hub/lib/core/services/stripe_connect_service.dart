import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../shared/constants/app_constants.dart';

class StripeConnectService {
  static final StripeConnectService _instance = StripeConnectService._internal();
  factory StripeConnectService() => _instance;
  StripeConnectService._internal();

  /// Connect Accountを作成
  Future<Map<String, dynamic>> createAccount(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/stripe/connect/restaurant'),
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
      print('[StripeConnect] Create account error: $e');
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
      print('[StripeConnect] Get status error: $e');
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
      print('[StripeConnect] Start onboarding error: $e');
      rethrow;
    }
  }
}
