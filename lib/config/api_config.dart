class ApiConfig {
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'https://api.centronis.com/api/v1');

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Tenant header key
  static const String tenantHeader = 'X-Tenant-Slug';

  // Session cookie names (Better Auth adds __Secure- prefix over HTTPS)
  static const String sessionCookieName = '__Secure-centronis.session_token';
  static const String sessionDataCookieName = '__Secure-centronis.session_data';
}
