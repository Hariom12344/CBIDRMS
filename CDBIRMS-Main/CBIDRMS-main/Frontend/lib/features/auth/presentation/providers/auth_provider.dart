import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isCheckingAuth;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isCheckingAuth = true,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isCheckingAuth,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository = AuthRepository();
  final StorageService _storageService = StorageService();

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isCheckingAuth: true);
    try {
      final savedUser = await _storageService.getUser();
      final token = await _storageService.getAccessToken();

      if (savedUser != null && token != null) {
        state = state.copyWith(user: savedUser, isCheckingAuth: false);
      } else {
        state = state.copyWith(user: null, isCheckingAuth: false);
      }
    } catch (_) {
      state = state.copyWith(user: null, isCheckingAuth: false);
    }
  }

  Future<bool> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.login(email, password);
      final user = res['user'] as UserModel;
      final accessToken = res['accessToken'] as String;
      final refreshToken = res['refreshToken'] as String?;

      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
      await _storageService.saveUser(user);

      state = state.copyWith(user: user, isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, res['message']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  Future<bool> register({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );

      if (res['accessToken'] != null && res['user'] != null) {
        final user = res['user'] as UserModel;
        await _storageService.saveTokens(
          accessToken: res['accessToken'],
          refreshToken: res['refreshToken'] ?? '',
        );
        await _storageService.saveUser(user);
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      if (context.mounted) {
        _showSnackBar(context, res['message']);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null) {
      await _repository.logout(refreshToken);
    }
    await _storageService.clearAll();
    state = AuthState(isCheckingAuth: false);
    if (context.mounted) {
      _showSnackBar(context, 'Logged out');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(BuildContext context, String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, res['message'] ?? 'Password reset link sent');
      }
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return {};
    }
  }

  Future<bool> resetPassword(BuildContext context, String token, String newPassword, {String? confirmPassword}) async {
    state = state.copyWith(isLoading: true);
    try {
      final msg = await _repository.resetPassword(token, newPassword, confirmPassword: confirmPassword);
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, msg);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  Future<bool> changePassword(
    BuildContext context, {
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final msg = await _repository.changePassword(currentPassword, newPassword);
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        _showSnackBar(context, msg);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
      return false;
    }
  }

  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
