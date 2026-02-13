import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';

final teachersServiceProvider = Provider<TeachersService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TeachersService(dioClient.dio);
});

class TeachersService {
  final Dio _dio;

  TeachersService(this._dio);

  Future<PaginatedResponse<Map<String, dynamic>>> getAll({
    int? page,
    int? limit,
    String? search,
    String? status,
  }) async {
    final response = await _dio.get('/teachers', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data,
    );
  }

  /// Get courses assigned to a teacher
  Future<List<TeacherCourseSubject>> getTeacherCourseSubjects(
    int teacherId, {
    int? academicPeriodId,
  }) async {
    final response = await _dio.get(
      '/teachers/$teacherId/course-subjects',
      queryParameters: {
        if (academicPeriodId != null) 'academicPeriodId': academicPeriodId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => TeacherCourseSubject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get teacher schedule grouped by day
  Future<Map<int, List<ScheduleEntry>>> getTeacherSchedule(
    int teacherId, {
    int? academicPeriodId,
  }) async {
    final response = await _dio.get(
      '/schedules/teacher/$teacherId',
      queryParameters: {
        if (academicPeriodId != null) 'academic_period_id': academicPeriodId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final scheduleData = data['data'] as Map<String, dynamic>;
    final result = <int, List<ScheduleEntry>>{};
    scheduleData.forEach((key, value) {
      final dayNum = int.tryParse(key) ?? 0;
      final entries = (value as List<dynamic>)
          .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (entries.isNotEmpty) {
        result[dayNum] = entries;
      }
    });
    return result;
  }
}

class TeacherCourseSubject {
  final int courseId;
  final String courseName;
  final int subjectId;
  final String subjectName;
  final bool isPrimary;
  final String? assignedAt;

  const TeacherCourseSubject({
    required this.courseId,
    required this.courseName,
    required this.subjectId,
    required this.subjectName,
    this.isPrimary = false,
    this.assignedAt,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory TeacherCourseSubject.fromJson(Map<String, dynamic> json) {
    return TeacherCourseSubject(
      courseId: _toInt(json['course_id']),
      courseName: json['course_name'] as String? ?? '',
      subjectId: _toInt(json['subject_id']),
      subjectName: json['subject_name'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      assignedAt: json['assigned_at'] as String?,
    );
  }
}

class ScheduleEntry {
  final int id;
  final int courseId;
  final int subjectId;
  final int teacherId;
  final int dayOfWeek;
  final String? classroom;
  final ScheduleCourse? course;
  final ScheduleSubject? subject;
  final ScheduleTimeBlock? timeBlock;

  const ScheduleEntry({
    required this.id,
    required this.courseId,
    required this.subjectId,
    required this.teacherId,
    required this.dayOfWeek,
    this.classroom,
    this.course,
    this.subject,
    this.timeBlock,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: _toInt(json['id']),
      courseId: _toInt(json['course_id']),
      subjectId: _toInt(json['subject_id']),
      teacherId: _toInt(json['teacher_id']),
      dayOfWeek: _toInt(json['day_of_week']),
      classroom: json['classroom'] as String?,
      course: json['course'] != null
          ? ScheduleCourse.fromJson(json['course'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? ScheduleSubject.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
      timeBlock: json['time_block'] != null
          ? ScheduleTimeBlock.fromJson(
              json['time_block'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ScheduleCourse {
  final int id;
  final String name;
  final String code;

  const ScheduleCourse(
      {required this.id, required this.name, required this.code});

  factory ScheduleCourse.fromJson(Map<String, dynamic> json) {
    return ScheduleCourse(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class ScheduleSubject {
  final int id;
  final String name;
  final String code;

  const ScheduleSubject(
      {required this.id, required this.name, required this.code});

  factory ScheduleSubject.fromJson(Map<String, dynamic> json) {
    return ScheduleSubject(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class ScheduleTimeBlock {
  final int id;
  final String startTime;
  final String endTime;

  const ScheduleTimeBlock(
      {required this.id, required this.startTime, required this.endTime});

  factory ScheduleTimeBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleTimeBlock(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );
  }
}
