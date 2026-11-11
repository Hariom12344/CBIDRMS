import 'package:dio/dio.dart';
import '../../app/constants/api_constants.dart';
import '../storage/storage_service.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  Dio get instance => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/login')) {
            final refreshToken = await _storageService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshRes = await _dio.post(
                  ApiConstants.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                if (refreshRes.statusCode == 200) {
                  final newAccessToken = refreshRes.data['accessToken'] ?? refreshRes.data['data']?['accessToken'];
                  final newRefreshToken = refreshRes.data['refreshToken'] ?? refreshRes.data['data']?['refreshToken'] ?? refreshToken;

                  if (newAccessToken != null) {
                    await _storageService.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';

                    final cloneReq = await _dio.request(
                      opts.path,
                      options: Options(method: opts.method, headers: opts.headers),
                      data: opts.data,
                      queryParameters: opts.queryParameters,
                    );
                    return handler.resolve(cloneReq);
                  }
                }
              } catch (_) {
                await _storageService.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
