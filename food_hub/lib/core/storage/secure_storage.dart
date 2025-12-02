import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/constants/app_constants.dart';

/// Secure storage wrapper for authentication tokens
/// This provides a simple static interface for token management
class SecureStorage {
  /// Get authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.authTokenKey);
  }

  /// Save authentication token
  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(AppConstants.authTokenKey, token);
  }

  /// Remove authentication token
  static Future<bool> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(AppConstants.authTokenKey);
  }
}
