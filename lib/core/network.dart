import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/secure_storage_service.dart';

class NetworkService {
  final Dio dio;
  final SecureStorageService _secureStorage;
  Function()? onUnauthenticated;

  NetworkService(this._secureStorage) : dio = Dio() {
    // Load config from dotenv or default
    final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5001';
    print("🌐 NetworkService initialized with Base URL: $baseUrl");

    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          // Check for token expired error code
          if (err.response?.statusCode == 401 &&
              err.response?.data != null &&
              (err.response?.data['message'] == 'token_expired' ||
                  err.response?.data['message'] ==
                      'Your token has expired! Please log in again.')) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry original request with new access token
              final requestOptions = err.requestOptions;
              final newToken = await _secureStorage.getAccessToken();
              requestOptions.headers['Authorization'] = 'Bearer $newToken';

              try {
                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:5001';
      // Use clean Dio client to avoid recursive intercepts
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

      final response = await refreshDio.post(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        final newAccess = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;

        await _secureStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }

    // Refresh failed - clear secure storage (force log out)
    await _secureStorage.clearAll();
    onUnauthenticated?.call();
    return false;
  }
}
