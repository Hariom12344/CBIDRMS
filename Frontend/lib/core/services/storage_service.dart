import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user_model.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _rememberEmailKey = 'remember_email';

  // Save Tokens
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  // Get Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Get Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Save User JSON
  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  // Get User
  Future<UserModel?> getUser() async {
    final str = await _storage.read(key: _userKey);
    if (str != null) {
      try {
        return UserModel.fromJson(jsonDecode(str));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Save Remembered Email
  Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _rememberEmailKey, value: email);
  }

  // Get Remembered Email
  Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _rememberEmailKey);
  }

  // Remove Remembered Email
  Future<void> clearRememberedEmail() async {
    await _storage.delete(key: _rememberEmailKey);
  }

  // Clear Session
  Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
