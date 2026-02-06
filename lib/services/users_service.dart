import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/user.dart';

final usersServiceProvider = Provider<UsersService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return UsersService(dioClient.dio);
});

class UsersService {
  final Dio _dio;

  UsersService(this._dio);

  Future<PaginatedResponse<User>> getAll({
    int? page,
    int? limit,
    String? search,
    String? role,
    bool? active,
  }) async {
    final response = await _dio.get('/users', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (role != null) 'role': role,
      if (active != null) 'active': active,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      User.fromJson,
    );
  }

  Future<ApiResponse<User>> getById(String id) async {
    final response = await _dio.get('/users/$id');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }
}
