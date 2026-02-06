import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/api_config.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

class DioClient {
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          if (!kIsWeb) 'Origin': 'https://api.centronis.com',
        },
        extra: kIsWeb ? {'withCredentials': true} : {},
      ),
    );

    // Allow self-signed certs and bypass SSL issues (debug only)
    if (!kIsWeb) {
      (dio.httpClientAdapter as dynamic).onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_loggingInterceptor());
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add tenant slug header
        final tenantSlug = await _storage.read(key: 'tenant_slug');
        if (tenantSlug != null) {
          options.headers[ApiConfig.tenantHeader] = tenantSlug;
        }

        // Build Cookie header with all saved session cookies
        final cookieParts = <String>[];
        final sessionToken = await _storage.read(key: 'session_token');
        if (sessionToken != null) {
          cookieParts.add('${ApiConfig.sessionCookieName}=$sessionToken');
          options.headers['Authorization'] = 'Bearer $sessionToken';
        }
        final sessionData = await _storage.read(key: 'session_data');
        if (sessionData != null) {
          cookieParts.add('${ApiConfig.sessionDataCookieName}=$sessionData');
        }
        if (cookieParts.isNotEmpty) {
          options.headers['Cookie'] = cookieParts.join('; ');
        }

        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Extract and persist all session cookies from Set-Cookie header
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (final cookie in cookies) {
            if (cookie.contains(ApiConfig.sessionCookieName)) {
              final token = _extractCookieValue(
                cookie,
                ApiConfig.sessionCookieName,
              );
              if (token != null) {
                await _storage.write(key: 'session_token', value: token);
              }
            }
            if (cookie.contains(ApiConfig.sessionDataCookieName)) {
              final data = _extractCookieValue(
                cookie,
                ApiConfig.sessionDataCookieName,
              );
              if (data != null) {
                await _storage.write(key: 'session_data', value: data);
              }
            }
          }
        }
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // ignore: avoid_print
        print('[API] ${options.method} ${options.uri}');
        // ignore: avoid_print
        if (options.headers['Authorization'] != null) {
          final auth = options.headers['Authorization'] as String;
          print('[API] Auth header: ${auth.substring(0, 20)}...');
        }
        // ignore: avoid_print
        if (options.headers['Cookie'] != null) {
          final cookie = options.headers['Cookie'] as String;
          print('[API] Cookie header: ${cookie.substring(0, 40)}...');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // ignore: avoid_print
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          print('[API] Set-Cookie: $cookies');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        // ignore: avoid_print
        print('[API ERROR] ${error.response?.statusCode} ${error.message}');
        handler.next(error);
      },
    );
  }

  String? _extractCookieValue(String cookie, String name) {
    final parts = cookie.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('$name=')) {
        return trimmed.substring(name.length + 1);
      }
    }
    return null;
  }
}
