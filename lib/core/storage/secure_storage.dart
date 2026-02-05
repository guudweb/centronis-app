import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  // Session
  Future<void> saveSessionToken(String token) =>
      _storage.write(key: 'session_token', value: token);

  Future<String?> getSessionToken() => _storage.read(key: 'session_token');

  Future<void> deleteSessionToken() => _storage.delete(key: 'session_token');

  // Tenant
  Future<void> saveTenantSlug(String slug) =>
      _storage.write(key: 'tenant_slug', value: slug);

  Future<String?> getTenantSlug() => _storage.read(key: 'tenant_slug');

  Future<void> deleteTenantSlug() => _storage.delete(key: 'tenant_slug');

  // Clear all
  Future<void> clearAll() => _storage.deleteAll();
}
