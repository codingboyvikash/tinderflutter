import 'package:dio/dio.dart';
import '../core/network.dart';
import '../services/secure_storage_service.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> register({required String email, required String password});
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> verifyOTP({required String email, required String otp});
  Future<Map<String, dynamic>> resendOTP({required String email});
  Future<Map<String, dynamic>> forgotPassword({required String email});
  Future<Map<String, dynamic>> resetPassword({required String email, required String otp, required String newPassword});
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String displayName,
  });
  Future<void> logout();
  Future<bool> checkAuthStatus();
  Future<Map<String, dynamic>?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final NetworkService _network;
  final SecureStorageService _secureStorage;

  AuthRepositoryImpl(this._network, this._secureStorage);

  @override
  Future<Map<String, dynamic>> register({required String email, required String password}) async {
    try {
      final response = await _network.dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await _network.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final resData = response.data;
      if (resData['status'] == 'success' && resData['data']['accessToken'] != null) {
        final data = resData['data'];
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await _secureStorage.saveUser(data['user']);
      }
      return resData;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOTP({required String email, required String otp}) async {
    try {
      final response = await _network.dio.post('/api/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });

      final resData = response.data;
      if (resData['status'] == 'success' && resData['data']['accessToken'] != null) {
        final data = resData['data'];
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await _secureStorage.saveUser(data['user']);
      }
      return resData;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> resendOTP({required String email}) async {
    try {
      final response = await _network.dio.post('/api/auth/resend-otp', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await _network.dio.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _network.dio.post('/api/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String displayName,
  }) async {
    try {
      final response = await _network.dio.post('/api/auth/social-login', data: {
        'provider': provider,
        'providerId': providerId,
        'email': email,
        'displayName': displayName,
      });

      final resData = response.data;
      if (resData['status'] == 'success' && resData['data']['accessToken'] != null) {
        final data = resData['data'];
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await _secureStorage.saveUser(data['user']);
      }
      return resData;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _network.dio.post('/api/auth/logout');
    } catch (e) {
      // Ignore network errors on logout, we want to clear local storage regardless
      print('Network logout error: $e');
    } finally {
      await _secureStorage.clearAll();
    }
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await _secureStorage.getAccessToken();
    final user = await _secureStorage.getUser();
    return token != null && user != null;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _secureStorage.getUser();
  }

  String _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data['message'] != null) {
      return error.response?.data['message'];
    }
    return error.message ?? 'An unknown error occurred';
  }
}
