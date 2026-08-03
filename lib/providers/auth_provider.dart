import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../repository/auth_repository.dart';
import '../services/secure_storage_service.dart';
import '../core/network.dart';

// Providers for dependencies
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final networkServiceProvider = Provider<NetworkService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return NetworkService(secureStorage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(network, secureStorage);
});

// Authentication States
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  const AuthAuthenticated(this.user);
}

class AuthPendingOTP extends AuthState {
  final String email;
  const AuthPendingOTP(this.email);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Authentication Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    checkStatus();
  }

  Future<void> _registerFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) {
        await _repository.updateFCMToken(token);
      }
    } catch (e) {
      print('Warning: Failed to fetch and upload FCM token: $e');
    }
  }

  Future<void> checkStatus() async {
    final isAuthenticated = await _repository.checkAuthStatus();
    if (isAuthenticated) {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        _registerFCMToken();
        return;
      }
    }
    state = const AuthUnauthenticated();
  }

  Future<void> register(String email, String password) async {
    state = const AuthLoading();
    try {
      final result = await _repository.register(email: email, password: password);
      if (result['status'] == 'success') {
        state = AuthPendingOTP(email);
      } else {
        state = AuthError(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final result = await _repository.login(email: email, password: password);
      final data = result['data'];
      
      if (data['isVerified'] == 'pending_otp') {
        state = AuthPendingOTP(email);
      } else {
        state = AuthAuthenticated(data['user']);
        _registerFCMToken();
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    state = const AuthLoading();
    try {
      final result = await _repository.verifyOTP(email: email, otp: otp);
      final data = result['data'];
      state = AuthAuthenticated(data['user']);
      _registerFCMToken();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> resendOTP(String email) async {
    try {
      await _repository.resendOTP(email: email);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AuthLoading();
    try {
      final result = await _repository.forgotPassword(email: email);
      if (result['status'] == 'success') {
        state = AuthPendingOTP(email); // OTP is sent, route to verification
      } else {
        state = AuthError(result['message'] ?? 'Forgot password request failed');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    state = const AuthLoading();
    try {
      final result = await _repository.resetPassword(email: email, otp: otp, newPassword: newPassword);
      if (result['status'] == 'success') {
        state = const AuthUnauthenticated(); // Password reset successful, let user login
      } else {
        state = AuthError(result['message'] ?? 'Reset password failed');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> loginWithProvider(String provider, String providerId, String email, String displayName) async {
    state = const AuthLoading();
    try {
      final result = await _repository.socialLogin(
        provider: provider,
        providerId: providerId,
        email: email,
        displayName: displayName,
      );
      final data = result['data'];
      state = AuthAuthenticated(data['user']);
      _registerFCMToken();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await _repository.logout();
    state = const AuthUnauthenticated();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
