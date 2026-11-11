import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';
import '../../models/auth_response_model.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  ApiService({Dio? dio}) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _setupInterceptors();
  }

  Dio get dioClient => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Access Token if present
          final token = await _storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle 401 Unauthorized & Token Refreshing
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/login')) {
            final refreshToken = await _storageService.getRefreshToken();

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Request a new access token
                final refreshResponse = await _dio.post(
                  ApiConstants.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['accessToken'] ?? refreshResponse.data['data']?['accessToken'];
                  final newRefreshToken = refreshResponse.data['refreshToken'] ?? refreshResponse.data['data']?['refreshToken'] ?? refreshToken;

                  if (newAccessToken != null) {
                    await _storageService.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Retry original request with new access token
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';

                    final cloneReq = await _dio.request(
                      opts.path,
                      options: Options(
                        method: opts.method,
                        headers: opts.headers,
                      ),
                      data: opts.data,
                      queryParameters: opts.queryParameters,
                    );

                    return handler.resolve(cloneReq);
                  }
                }
              } catch (_) {
                // Refresh failed - wipe session
                await _storageService.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Register Method
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // Login Method
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return AuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // Logout Method
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {}
  }

  // Forgot Password Method
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
      return response.data['message'] ?? 'Password reset link sent to your email';
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // Reset Password Method
  Future<String> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.put(
        ApiConstants.resetPassword,
        data: {
          'resetToken': token,
          'token': token,
          'newPassword': newPassword,
        },
      );
      return response.data['message'] ?? 'Password reset successfully';
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // Error Helper
  String _parseError(DioException error) {
    if (error.response?.data != null && error.response?.data is Map) {
      final map = error.response?.data as Map;
      return map['message'] ?? map['error'] ?? 'An unexpected error occurred';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your backend server.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to backend server (http://localhost:5000). Ensure the backend is running.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }
}
