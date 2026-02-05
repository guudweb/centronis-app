class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api/v1');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Tenant header key
  static const String tenantHeader = 'X-Tenant-Slug';

  // Session cookie name
  static const String sessionCookieName = 'better-auth.session_token';
}
