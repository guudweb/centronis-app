import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthService(dioClient.dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  /// Sign in with email and password via Better Auth
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final response = await _dio.post(
      '/auth/sign-in/email',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _dio.post(
      '/auth/sign-up/email',
      data: {
        'email': email,
        'password': password,
        'name': '$firstName $lastName',
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone ?? '',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get current user profile from backend
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get Better Auth session status
  Future<Map<String, dynamic>> getSession() async {
    final response = await _dio.get('/auth/get-session');
    return response.data as Map<String, dynamic>;
  }

  /// Sign out
  Future<void> signOut() async {
    await _dio.post('/auth/sign-out');
  }

  /// Request password reset
  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  /// Reset password with token
  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post('/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// Change password (authenticated)
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'revokeOtherSessions': false,
    });
  }

  /// Validate parent activation token
  Future<Map<String, dynamic>> validateParentToken(String token) async {
    final response = await _dio.get('/auth/parent-activation/$token');
    return response.data as Map<String, dynamic>;
  }

  /// Activate parent account
  Future<Map<String, dynamic>> activateParentAccount(
      String token, String password) async {
    final response = await _dio.post(
      '/auth/parent-activation/$token',
      data: {'password': password},
    );
    return response.data as Map<String, dynamic>;
  }
}
