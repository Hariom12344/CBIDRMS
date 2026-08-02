import 'package:dio/dio.dart';
import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data['data'] ?? response.data;
      return {
        'message': response.data['message'] ?? 'Login successful',
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
        'user': UserModel.fromJson(data['user']),
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        },
      );
      final data = response.data['data'] ?? response.data;
      return {
        'message': response.data['message'] ?? 'Account created successfully',
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
        'user': data['user'] != null ? UserModel.fromJson(data['user']) : null,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout(String refreshToken) async {
    try {
      await _dioClient.instance.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {}
  }

  // Forgot Password
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dioClient.instance.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      return response.data['message'] ?? 'Password reset link sent to email';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reset Password
  Future<String> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dioClient.instance.put(
        ApiConstants.resetPassword,
        data: {'resetToken': token, 'token': token, 'newPassword': newPassword},
      );
      return response.data['message'] ?? 'Password reset successfully';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['message'] ?? map['error'] ?? 'An error occurred';
    }
    return 'Connection error. Please check your backend at http://localhost:5000/api';
  }
}
