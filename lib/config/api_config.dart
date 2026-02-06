class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://api.centronis.com/api/v1');

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Tenant header key
  static const String tenantHeader = 'X-Tenant-Slug';

  // Session cookie name
  static const String sessionCookieName = 'better-auth.session_token';
}
