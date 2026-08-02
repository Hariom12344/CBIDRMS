import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  String? _accessToken;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  bool _rememberMe = false;
  String? _rememberedEmail;

  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _user != null && _accessToken != null;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  // Initial Auth Verification Boot Check
  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final savedUser = await _storageService.getUser();
      final token = await _storageService.getAccessToken();
      _rememberedEmail = await _storageService.getRememberedEmail();

      if (_rememberedEmail != null && _rememberedEmail!.isNotEmpty) {
        _rememberMe = true;
      }

      if (savedUser != null && token != null) {
        _user = savedUser;
        _accessToken = token;
      }
    } catch (_) {
      _user = null;
      _accessToken = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  // Show Floating SnackBar Message
  void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.emerald.shade600,
      ),
    );
  }

  // Login Handler
  Future<bool> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(email: email, password: password);

      if (result.accessToken != null && result.user != null) {
        _user = result.user;
        _accessToken = result.accessToken;

        await _storageService.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken ?? '',
        );
        await _storageService.saveUser(result.user!);

        if (_rememberMe) {
          await _storageService.saveRememberedEmail(email);
        } else {
          await _storageService.clearRememberedEmail();
        }

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          showSnackBar(context, result.message.isNotEmpty ? result.message : 'Login successful!');
        }
        return true;
      } else {
        throw 'Invalid user session received from server';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  // Register Handler
  Future<bool> register({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, result.message.isNotEmpty ? result.message : 'Account created successfully!');
      }

      if (result.accessToken != null && result.user != null) {
        _user = result.user;
        _accessToken = result.accessToken;

        await _storageService.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken ?? '',
        );
        await _storageService.saveUser(result.user!);
        notifyListeners();
        return true;
      }
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  // Logout Handler
  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null) {
      await _apiService.logout(refreshToken);
    }
    await _storageService.clearAll();
    _user = null;
    _accessToken = null;
    _isLoading = false;
    notifyListeners();

    if (context.mounted) {
      showSnackBar(context, 'Logged out successfully');
    }
  }

  // Forgot Password Handler
  Future<bool> forgotPassword({
    required BuildContext context,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final message = await _apiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, message);
      }
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  // Reset Password Handler
  Future<bool> resetPassword({
    required BuildContext context,
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final message = await _apiService.resetPassword(token, newPassword);
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, message);
      }
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }
}
