import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

final enrollmentsServiceProvider = Provider<EnrollmentsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return EnrollmentsService(dioClient.dio);
});

class EnrollmentsService {
  final Dio _dio;

  EnrollmentsService(this._dio);

  /// Get enrollments for a course (to get student list)
  Future<List<EnrolledStudent>> getCourseEnrollments(int courseId) async {
    final response =
        await _dio.get('/enrollments', queryParameters: {'course_id': courseId});
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => EnrolledStudent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get enrollments for a student
  Future<List<dynamic>> getStudentEnrollments(int studentId) async {
    final response =
        await _dio.get('/enrollments/student/$studentId');
    final data = response.data as Map<String, dynamic>;
    return data['data'] as List<dynamic>? ?? [];
  }

  /// Get enrollments for the current student (self)
  Future<List<StudentEnrollment>> getMyEnrollments({
    int? studentId,
    String? status,
  }) async {
    final response = await _dio.get('/enrollments', queryParameters: {
      if (studentId != null) 'studentId': studentId,
      if (status != null) 'status': status,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class EnrolledStudent {
  final int enrollmentId;
  final int studentId;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String status;

  const EnrolledStudent({
    required this.enrollmentId,
    required this.studentId,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.status = 'active',
  });

  String get fullName => '$firstName $lastName';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory EnrolledStudent.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final user = student?['user'] as Map<String, dynamic>?;
    return EnrolledStudent(
      enrollmentId: _toInt(json['id']),
      studentId: _toInt(student?['id'] ?? json['student_id']),
      studentCode: student?['student_code'] as String? ?? '',
      firstName: user?['first_name'] as String? ?? '',
      lastName: user?['last_name'] as String? ?? '',
      email: user?['email'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class StudentEnrollment {
  final int id;
  final String enrollmentDate;
  final String status;
  final double? finalGrade;
  final EnrollmentCourse? course;
  final EnrollmentPeriod? academicPeriod;

  const StudentEnrollment({
    required this.id,
    required this.enrollmentDate,
    required this.status,
    this.finalGrade,
    this.course,
    this.academicPeriod,
  });

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    return StudentEnrollment(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      enrollmentDate: json['enrollment_date'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      finalGrade: (json['final_grade'] as num?)?.toDouble(),
      course: json['course'] != null
          ? EnrollmentCourse.fromJson(json['course'] as Map<String, dynamic>)
          : null,
      academicPeriod: json['academic_period'] != null
          ? EnrollmentPeriod.fromJson(
              json['academic_period'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EnrollmentCourse {
  final int id;
  final String name;
  final String code;
  final String? section;
  final String? level;

  const EnrollmentCourse({
    required this.id,
    required this.name,
    required this.code,
    this.section,
    this.level,
  });

  factory EnrollmentCourse.fromJson(Map<String, dynamic> json) {
    return EnrollmentCourse(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      section: json['section'] as String?,
      level: json['level'] as String?,
    );
  }
}

class EnrollmentPeriod {
  final int id;
  final String name;
  final String code;

  const EnrollmentPeriod({
    required this.id,
    required this.name,
    required this.code,
  });

  factory EnrollmentPeriod.fromJson(Map<String, dynamic> json) {
    return EnrollmentPeriod(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}
