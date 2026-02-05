import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/institution.dart';

class TenantState {
  final Institution? tenant;
  final bool loading;
  final String? error;
  final bool initialized;

  const TenantState({
    this.tenant,
    this.loading = false,
    this.error,
    this.initialized = false,
  });

  bool get isResolved => tenant != null;
  String get tenantName => tenant?.name ?? 'Centronis';
  String? get tenantLogo => tenant?.logoUrl;
  String? get tenantSlug => tenant?.slug;

  TenantState copyWith({
    Institution? tenant,
    bool? loading,
    String? error,
    bool? initialized,
    bool clearTenant = false,
    bool clearError = false,
  }) {
    return TenantState(
      tenant: clearTenant ? null : (tenant ?? this.tenant),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      initialized: initialized ?? this.initialized,
    );
  }
}

class TenantNotifier extends StateNotifier<TenantState> {
  final Dio _dio;
  final SecureStorageService _storage;

  TenantNotifier(this._dio, this._storage) : super(const TenantState());

  /// Resolve tenant by slug
  Future<bool> resolveTenantBySlug(String slug) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final response = await _dio.get('/institutions/by-slug/$slug');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final institution =
            Institution.fromJson(data['data'] as Map<String, dynamic>);
        await _storage.saveTenantSlug(slug);
        state = state.copyWith(
          tenant: institution,
          initialized: true,
          loading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          error: data['message'] as String? ?? 'Institución no encontrada',
          initialized: true,
          loading: false,
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMsg;
      if (e.response?.statusCode == 404) {
        errorMsg = 'Institución no encontrada';
      } else if (e.response?.statusCode == 403) {
        errorMsg = 'Esta institución ha sido desactivada';
      } else {
        errorMsg = 'Error al cargar la institución';
      }
      state = state.copyWith(
        error: errorMsg,
        initialized: true,
        loading: false,
      );
      return false;
    }
  }

  /// Initialize from saved tenant slug
  Future<bool> initializeFromStorage() async {
    final slug = await _storage.getTenantSlug();
    if (slug != null) {
      return resolveTenantBySlug(slug);
    }
    state = state.copyWith(initialized: true);
    return true;
  }

  /// Clear tenant context
  Future<void> clearTenant() async {
    await _storage.deleteTenantSlug();
    state = const TenantState(initialized: true);
  }
}

final tenantProvider =
    StateNotifierProvider<TenantNotifier, TenantState>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return TenantNotifier(dioClient.dio, storage);
});
