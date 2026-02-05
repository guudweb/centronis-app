import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/grade.dart';

final gradesServiceProvider = Provider<GradesService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return GradesService(dioClient.dio);
});

class GradesService {
  final Dio _dio;

  GradesService(this._dio);

  Future<PaginatedResponse<Grade>> getAll({
    int? page,
    int? limit,
    int? studentId,
    int? courseId,
    int? subjectId,
    int? academicPeriodId,
  }) async {
    final response = await _dio.get('/grades', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (studentId != null) 'student_id': studentId,
      if (courseId != null) 'course_id': courseId,
      if (subjectId != null) 'subject_id': subjectId,
      if (academicPeriodId != null) 'academic_period_id': academicPeriodId,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Grade.fromJson,
    );
  }

  Future<ApiResponse<Grade>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/grades', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Grade.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Grade>>> createBulk(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/grades/bulk', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => Grade.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<Grade>> update(
      int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/grades/$id', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Grade.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/grades/$id');
  }

  Future<ApiResponse<GradeSummary>> getStudentSummary(
    int studentId, {
    int? academicPeriodId,
  }) async {
    final response = await _dio.get(
      '/grades/student/$studentId/summary',
      queryParameters: {
        if (academicPeriodId != null) 'academicPeriodId': academicPeriodId,
      },
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => GradeSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> generateReportCard({
    required int studentId,
    required int academicPeriodId,
  }) async {
    final response = await _dio.post('/grades/report-card', data: {
      'studentId': studentId,
      'academicPeriodId': academicPeriodId,
    });
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );
  }
}
