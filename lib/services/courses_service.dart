import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/course.dart';

final coursesServiceProvider = Provider<CoursesService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CoursesService(dioClient.dio);
});

class CoursesService {
  final Dio _dio;

  CoursesService(this._dio);

  Future<PaginatedResponse<Course>> getAll({
    int? page,
    int? limit,
    String? search,
    int? academicPeriodId,
    bool? active,
    String? level,
    String? section,
  }) async {
    final response = await _dio.get('/courses', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (academicPeriodId != null) 'academic_period_id': academicPeriodId,
      if (active != null) 'active': active,
      if (level != null) 'level': level,
      if (section != null) 'section': section,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Course.fromJson,
    );
  }

  Future<ApiResponse<Course>> getById(int id) async {
    final response = await _dio.get('/courses/$id');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Course.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Course>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/courses', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Course.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Course>> update(
      int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/courses/$id', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Course.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/courses/$id');
  }
}
