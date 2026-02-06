import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

final parentPortalServiceProvider = Provider<ParentPortalService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ParentPortalService(dioClient.dio);
});

class ParentPortalService {
  final Dio _dio;

  ParentPortalService(this._dio);

  /// Get parent's linked children
  Future<List<ParentChild>> getChildren() async {
    final response = await _dio.get('/parent/children');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ParentChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get detailed info for a specific child
  Future<ParentChildDetail> getChildDetail(int studentId) async {
    final response = await _dio.get('/parent/children/$studentId');
    final data = response.data as Map<String, dynamic>;
    return ParentChildDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Get child's assignments
  Future<Map<String, dynamic>> getChildAssignments(
    int studentId, {
    String? status,
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get(
      '/parent/children/$studentId/assignments',
      queryParameters: {
        if (status != null) 'status': status,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

class ParentChild {
  final int id;
  final String studentCode;
  final String status;
  final String relationship;
  final ParentChildUser user;
  final ParentChildEnrollment? currentEnrollment;

  const ParentChild({
    required this.id,
    required this.studentCode,
    required this.status,
    required this.relationship,
    required this.user,
    this.currentEnrollment,
  });

  String get fullName => '${user.firstName} ${user.lastName}';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    return ParentChild(
      id: _toInt(json['id']),
      studentCode: json['student_code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      user: ParentChildUser.fromJson(json['user'] as Map<String, dynamic>),
      currentEnrollment: json['current_enrollment'] != null
          ? ParentChildEnrollment.fromJson(
              json['current_enrollment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ParentChildUser {
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;

  const ParentChildUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
  });

  factory ParentChildUser.fromJson(Map<String, dynamic> json) {
    return ParentChildUser(
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}

class ParentChildEnrollment {
  final int id;
  final Map<String, dynamic>? course;
  final Map<String, dynamic>? academicPeriod;

  const ParentChildEnrollment({
    required this.id,
    this.course,
    this.academicPeriod,
  });

  String get courseName =>
      course?['name'] as String? ?? 'Sin curso asignado';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory ParentChildEnrollment.fromJson(Map<String, dynamic> json) {
    return ParentChildEnrollment(
      id: _toInt(json['id']),
      course: json['course'] as Map<String, dynamic>?,
      academicPeriod: json['academic_period'] as Map<String, dynamic>?,
    );
  }
}

class ParentChildDetail {
  final int id;
  final String studentCode;
  final String status;
  final String? admissionDate;
  final ParentChildUser user;
  final ParentChildEnrollment? currentEnrollment;
  final String? relationship;
  final ChildGradesInfo? grades;
  final ChildAttendanceInfo? attendance;

  const ParentChildDetail({
    required this.id,
    required this.studentCode,
    required this.status,
    this.admissionDate,
    required this.user,
    this.currentEnrollment,
    this.relationship,
    this.grades,
    this.attendance,
  });

  String get fullName => '${user.firstName} ${user.lastName}';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory ParentChildDetail.fromJson(Map<String, dynamic> json) {
    return ParentChildDetail(
      id: _toInt(json['id']),
      studentCode: json['student_code'] as String? ?? '',
      status: json['status'] as String? ?? '',
      admissionDate: json['admission_date'] as String?,
      user: ParentChildUser.fromJson(json['user'] as Map<String, dynamic>),
      currentEnrollment: json['current_enrollment'] != null
          ? ParentChildEnrollment.fromJson(
              json['current_enrollment'] as Map<String, dynamic>)
          : null,
      relationship: json['relationship'] as String?,
      grades: json['grades'] != null
          ? ChildGradesInfo.fromJson(json['grades'] as Map<String, dynamic>)
          : null,
      attendance: json['attendance'] != null
          ? ChildAttendanceInfo.fromJson(
              json['attendance'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChildGradesInfo {
  final List<Map<String, dynamic>> recent;
  final double? average;

  const ChildGradesInfo({required this.recent, this.average});

  factory ChildGradesInfo.fromJson(Map<String, dynamic> json) {
    return ChildGradesInfo(
      recent: (json['recent'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      average: (json['average'] as num?)?.toDouble(),
    );
  }
}

class ChildAttendanceInfo {
  final ChildAttendanceSummary summary;
  final List<Map<String, dynamic>> recent;

  const ChildAttendanceInfo({required this.summary, required this.recent});

  factory ChildAttendanceInfo.fromJson(Map<String, dynamic> json) {
    return ChildAttendanceInfo(
      summary: ChildAttendanceSummary.fromJson(
          json['summary'] as Map<String, dynamic>),
      recent: (json['recent'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class ChildAttendanceSummary {
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int total;
  final double percentage;

  const ChildAttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.total,
    required this.percentage,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory ChildAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return ChildAttendanceSummary(
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      late: _toInt(json['late']),
      excused: _toInt(json['excused']),
      total: _toInt(json['total']),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
