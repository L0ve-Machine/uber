import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/constants/app_constants.dart';
import '../../shared/models/user_model.dart';

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Storage service for managing local data persistence
class StorageService {
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (auto-initialize if needed)
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ==================== Authentication ====================

  /// Save authentication token
  Future<bool> saveAuthToken(String token) async {
    final prefs = await _preferences;
    return await prefs.setString(AppConstants.authTokenKey, token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.authTokenKey);
  }

  /// Save user data
  Future<bool> saveUser(UserModel user) async {
    final prefs = await _preferences;
    final userJson = jsonEncode(user.toJson());
    final results = await Future.wait([
      prefs.setInt(AppConstants.userIdKey, user.id),
      prefs.setString(AppConstants.userTypeKey, user.userType),
      prefs.setString('user_data', userJson),
      prefs.setBool(AppConstants.isLoggedInKey, true),
    ]);
    return results.every((result) => result);
  }

  /// Get user data
  Future<UserModel?> getUser() async {
    final prefs = await _preferences;
    final userJson = prefs.getString('user_data');
    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  /// Get user ID
  Future<int?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getInt(AppConstants.userIdKey);
  }

  /// Get user type
  Future<String?> getUserType() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.userTypeKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  /// Clear all authentication data
  Future<bool> clearAuthData() async {
    final prefs = await _preferences;
    final results = await Future.wait([
      prefs.remove(AppConstants.authTokenKey),
      prefs.remove(AppConstants.userIdKey),
      prefs.remove(AppConstants.userTypeKey),
      prefs.remove('user_data'),
      prefs.setBool(AppConstants.isLoggedInKey, false),
    ]);
    return results.every((result) => result);
  }

  // ==================== Generic Methods ====================

  /// Save string value
  Future<bool> setString(String key, String value) async {
    final prefs = await _preferences;
    return await prefs.setString(key, value);
  }

  /// Get string value
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    final prefs = await _preferences;
    return await prefs.setInt(key, value);
  }

  /// Get int value
  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    final prefs = await _preferences;
    return await prefs.setBool(key, value);
  }

  /// Get bool value
  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  /// Remove value by key
  Future<bool> remove(String key) async {
    final prefs = await _preferences;
    return await prefs.remove(key);
  }

  /// Clear all data
  Future<bool> clearAll() async {
    final prefs = await _preferences;
    return await prefs.clear();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _preferences;
    return prefs.containsKey(key);
  }
}
