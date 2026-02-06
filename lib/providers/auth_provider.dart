import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool loading;
  final bool initialized;
  final bool sessionActive;
  final String? error;

  const AuthState({
    this.user,
    this.loading = false,
    this.initialized = false,
    this.sessionActive = false,
    this.error,
  });

  bool get isAuthenticated => sessionActive && user != null;
  String get userRole => user?.role?.code ?? user?.roleCode ?? '';
  bool get isAdmin =>
      ['admin', 'super_admin'].contains(userRole.toLowerCase());
  bool get isSuperAdmin => userRole.toLowerCase() == 'super_admin';
  bool get isDirector => userRole.toLowerCase() == 'director';
  bool get isTeacher => userRole.toLowerCase() == 'teacher';
  bool get isStudent => userRole.toLowerCase() == 'student';
  bool get isSecretary => userRole.toLowerCase() == 'secretary';
  bool get isParent => userRole.toLowerCase() == 'parent';

  AuthState copyWith({
    User? user,
    bool? loading,
    bool? initialized,
    bool? sessionActive,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      sessionActive: sessionActive ?? this.sessionActive,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Auth notifier
class AuthNotifier extends Notifier<AuthState> {
  AuthService get _authService => ref.read(authServiceProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  @override
  AuthState build() => const AuthState();

  /// Initialize - check if there's an existing session
  Future<void> initialize() async {
    if (state.initialized) return;

    try {
      // Check if we have a saved token first
      final savedToken = await _storage.getSessionToken();
      if (savedToken == null) {
        state = state.copyWith(sessionActive: false, initialized: true);
        return;
      }

      final sessionData = await _authService.getSession();
      if (sessionData['session'] != null && sessionData['user'] != null) {
        state = state.copyWith(sessionActive: true);
        await fetchCurrentUser();
      } else {
        state = state.copyWith(sessionActive: false);
      }
    } catch (_) {
      state = state.copyWith(sessionActive: false);
    } finally {
      state = state.copyWith(initialized: true);
    }
  }

  /// Sign in with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _authService.signIn(email, password);
      // Token is extracted from Set-Cookie by the DioClient interceptor.
      // Don't save data['token'] here - it's only the token ID without
      // the signature, while the cookie has the full signed value.
      // Give the interceptor a moment to persist the cookie.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      state = state.copyWith(sessionActive: true);
      final success = await fetchCurrentUser();
      return success;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMsg = 'Error al iniciar sesión';
      if (responseData is Map<String, dynamic>) {
        errorMsg = responseData['message'] as String? ?? errorMsg;
      }
      // ignore: avoid_print
      print('[AUTH] Login error: ${e.response?.statusCode} $responseData');
      state = state.copyWith(error: errorMsg, loading: false);
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('[AUTH] Login unexpected error: $e');
      state = state.copyWith(
        error: 'Error al iniciar sesión',
        loading: false,
      );
      return false;
    }
  }

  /// Register a new account
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Error al crear la cuenta',
        loading: false,
      );
      return false;
    }
  }

  /// Fetch current user from backend
  Future<bool> fetchCurrentUser() async {
    if (!state.sessionActive) return false;

    state = state.copyWith(loading: true);
    try {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(user: user, loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false);
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      await _authService.changePassword(currentPassword, newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(loading: true);
    try {
      await _authService.signOut();
    } catch (_) {
      // Continue with local cleanup even if API call fails
    }
    await _storage.clearAll();
    state = const AuthState(initialized: true);
  }

  /// Get the dashboard route for the current user role
  String getDashboardRoute() {
    if (state.isSuperAdmin || state.isAdmin) return '/admin/dashboard';
    if (state.isDirector) return '/director/dashboard';
    if (state.isSecretary) return '/secretary/dashboard';
    if (state.isTeacher) return '/teacher/dashboard';
    if (state.isStudent) return '/student/dashboard';
    if (state.isParent) return '/parent/dashboard';
    // Fallback to admin dashboard for unknown roles to avoid route crash
    // ignore: avoid_print
    print('[AUTH] Unknown role "${state.userRole}", falling back to admin dashboard');
    return '/admin/dashboard';
  }
}

// Provider
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
