import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/attendance.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AttendanceService(dioClient.dio);
});

class AttendanceService {
  final Dio _dio;

  AttendanceService(this._dio);

  Future<PaginatedResponse<Attendance>> getAll({
    int? page,
    int? limit,
    int? courseId,
    int? studentId,
    String? date,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get('/attendance', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (courseId != null) 'course_id': courseId,
      if (studentId != null) 'student_id': studentId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Attendance.fromJson,
    );
  }

  Future<ApiResponse<Attendance>> mark(Map<String, dynamic> data) async {
    final response = await _dio.post('/attendance/mark', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Attendance.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> bulkMark(BulkAttendanceData data) async {
    await _dio.post('/attendance/bulk', data: data.toJson());
  }

  Future<ApiResponse<List<Attendance>>> getByStudent(
    int studentId, {
    int? courseId,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get(
      '/attendance/student/$studentId',
      queryParameters: {
        if (courseId != null) 'course_id': courseId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) {
        final list = data is List
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : <dynamic>[];
        return list
            .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<List<Attendance>>> getByCourse(
    int courseId, {
    String? date,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final response = await _dio.get(
      '/attendance/course/$courseId',
      queryParameters: {
        if (date != null) 'date': date,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (status != null) 'status': status,
      },
    );
    final json = response.data as Map<String, dynamic>;
    // API returns grouped by date: data: [{ date, records: [...], stats }]
    final groups = json['data'] as List<dynamic>? ?? [];
    final allRecords = <Attendance>[];
    for (final group in groups) {
      if (group is Map<String, dynamic>) {
        final records = group['records'] as List<dynamic>? ?? [];
        for (final r in records) {
          allRecords.add(Attendance.fromJson(r as Map<String, dynamic>));
        }
      }
    }
    return ApiResponse<List<Attendance>>(
      success: json['success'] == true,
      message: json['message'] as String? ?? '',
      data: allRecords,
    );
  }

  Future<ApiResponse<List<AttendanceReport>>> getReport({
    int? studentId,
    int? courseId,
    String? startDate,
    String? endDate,
  }) async {
    final response = await _dio.get('/attendance/report', queryParameters: {
      if (studentId != null) 'student_id': studentId,
      if (courseId != null) 'course_id': courseId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) {
        final list = data is List
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
                ? data['data'] as List
                : <dynamic>[];
        return list
            .map((e) => AttendanceReport.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
