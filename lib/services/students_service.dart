import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/student.dart';

final studentsServiceProvider = Provider<StudentsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return StudentsService(dioClient.dio);
});

class StudentsService {
  final Dio _dio;

  StudentsService(this._dio);

  Future<PaginatedResponse<Student>> getAll({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? admissionYear,
    int? courseId,
  }) async {
    final response = await _dio.get('/students', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
      if (admissionYear != null) 'admission_year': admissionYear,
      if (courseId != null) 'course_id': courseId,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Student.fromJson,
    );
  }

  Future<ApiResponse<Student>> getById(int id) async {
    final response = await _dio.get('/students/$id');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Student>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/students', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Student>> update(
      int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/students/$id', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Student.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/students/$id');
  }

  Future<ApiResponse<List<StudentSearchResult>>> searchLight(
    String search, {
    int limit = 10,
  }) async {
    final response = await _dio.get('/students/search-light', queryParameters: {
      'search': search,
      'limit': limit,
    });
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => StudentSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
