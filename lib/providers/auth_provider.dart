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
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SecureStorageService _storage;

  AuthNotifier(this._authService, this._storage) : super(const AuthState());

  /// Initialize - check if there's an existing session
  Future<void> initialize() async {
    if (state.initialized) return;

    try {
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
      state = state.copyWith(sessionActive: true);
      final success = await fetchCurrentUser();
      return success;
    } catch (e) {
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
    if (state.isAdmin || state.isDirector) return '/admin/dashboard';
    if (state.isSecretary) return '/secretary/dashboard';
    if (state.isTeacher) return '/teacher/dashboard';
    if (state.isStudent) return '/student/dashboard';
    if (state.isParent) return '/parent/dashboard';
    return '/';
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(authService, storage);
});
