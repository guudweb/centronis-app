import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/assignment.dart';

final assignmentsServiceProvider = Provider<AssignmentsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AssignmentsService(dioClient.dio);
});

class AssignmentsService {
  final Dio _dio;

  AssignmentsService(this._dio);

  Future<PaginatedResponse<Assignment>> getAll({
    int? page,
    int? limit,
    int? courseId,
    int? subjectId,
    int? teacherId,
    String? assignmentType,
    bool? isPublished,
    String? sort,
  }) async {
    final response = await _dio.get('/assignments', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (courseId != null) 'course_id': courseId,
      if (subjectId != null) 'subject_id': subjectId,
      if (teacherId != null) 'teacher_id': teacherId,
      if (assignmentType != null) 'assignment_type': assignmentType,
      if (isPublished != null) 'is_published': isPublished,
      if (sort != null) 'sort': sort,
    });
    final data = response.data as Map<String, dynamic>;
    final list = (data['data']?['assignments'] ?? data['data']) as List<dynamic>? ?? [];
    final pagination = data['data']?['pagination'] ?? data['pagination'];
    return PaginatedResponse<Assignment>(
      success: data['success'] as bool? ?? true,
      message: data['message'] as String? ?? '',
      data: list
          .map((e) => Assignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: pagination != null
          ? Pagination.fromJson(pagination as Map<String, dynamic>)
          : const Pagination(total: 0, page: 1, limit: 10, totalPages: 0, hasNext: false, hasPrev: false),
    );
  }

  Future<ApiResponse<Assignment>> getById(int id) async {
    final response = await _dio.get('/assignments/$id');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Assignment.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get submissions for an assignment (teacher/admin)
  Future<List<Submission>> getSubmissions(
    int assignmentId, {
    int? page,
    int? limit,
    String? status,
  }) async {
    final response = await _dio.get(
      '/assignments/$assignmentId/submissions',
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (status != null) 'status': status,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data']?['submissions'] ?? data['data']) as List<dynamic>? ?? [];
    return list
        .map((e) => Submission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Grade a submission (teacher/admin)
  Future<void> gradeSubmission(
    int assignmentId,
    int submissionId, {
    required double grade,
    String? feedback,
    List<Map<String, dynamic>>? openEndedGrades,
  }) async {
    await _dio.put(
      '/assignments/$assignmentId/submissions/$submissionId/grade',
      data: {
        'grade': grade,
        if (feedback != null) 'feedback': feedback,
        if (openEndedGrades != null) 'open_ended_grades': openEndedGrades,
      },
    );
  }

  /// Submit an assignment (student)
  Future<Submission> submit(
    int assignmentId, {
    String? submissionText,
    String? fileUrl,
    String? fileName,
    List<Map<String, dynamic>>? answers,
  }) async {
    final response = await _dio.post(
      '/assignments/$assignmentId/submit',
      data: {
        if (submissionText != null) 'submission_text': submissionText,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
        if (answers != null) 'answers': answers,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return Submission.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get student's own submission
  Future<Submission?> getMySubmission(int assignmentId) async {
    try {
      final response =
          await _dio.get('/assignments/$assignmentId/my-submission');
      final data = response.data as Map<String, dynamic>;
      if (data['data'] == null) return null;
      return Submission.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}
