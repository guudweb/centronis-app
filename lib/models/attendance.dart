class Attendance {
  final int id;
  final int studentId;
  final int courseId;
  final int? subjectId;
  final String date;
  final String status; // present, absent, late, excused
  final String? notes;
  final int? markedBy;
  final String createdAt;
  final String updatedAt;
  final AttendanceStudentRef? student;
  final AttendanceCourseRef? course;
  final AttendanceSubjectRef? subject;

  const Attendance({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.subjectId,
    required this.date,
    required this.status,
    this.notes,
    this.markedBy,
    this.createdAt = '',
    this.updatedAt = '',
    this.student,
    this.course,
    this.subject,
  });

  String? get courseName => course?.name;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      courseId: json['course_id'] as int,
      subjectId: json['subject_id'] as int?,
      date: json['date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      markedBy: json['marked_by'] as int?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      student: json['student'] != null
          ? AttendanceStudentRef.fromJson(
              json['student'] as Map<String, dynamic>)
          : null,
      course: json['course'] != null
          ? AttendanceCourseRef.fromJson(
              json['course'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? AttendanceSubjectRef.fromJson(
              json['subject'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AttendanceStudentRef {
  final int id;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String email;

  const AttendanceStudentRef({
    required this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  factory AttendanceStudentRef.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AttendanceStudentRef(
      id: json['id'] as int,
      studentCode: json['student_code'] as String? ?? '',
      firstName: user?['first_name'] as String? ?? '',
      lastName: user?['last_name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
    );
  }
}

class AttendanceCourseRef {
  final int id;
  final String name;
  final String code;

  const AttendanceCourseRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory AttendanceCourseRef.fromJson(Map<String, dynamic> json) {
    return AttendanceCourseRef(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class AttendanceSubjectRef {
  final int id;
  final String name;
  final String code;

  const AttendanceSubjectRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory AttendanceSubjectRef.fromJson(Map<String, dynamic> json) {
    return AttendanceSubjectRef(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class AttendanceReport {
  final int studentId;
  final String studentCode;
  final String studentName;
  final int? courseId;
  final String? courseName;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendanceRate;

  const AttendanceReport({
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    this.courseId,
    this.courseName,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendanceRate,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      studentId: json['student_id'] as int,
      studentCode: json['student_code'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      courseId: json['course_id'] as int?,
      courseName: json['course_name'] as String?,
      totalClasses: json['total_classes'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      lateCount: json['late_count'] as int? ?? 0,
      excusedCount: json['excused_count'] as int? ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BulkAttendanceData {
  final int courseId;
  final int? subjectId;
  final String date;
  final List<BulkAttendanceEntry> attendances;

  const BulkAttendanceData({
    required this.courseId,
    this.subjectId,
    required this.date,
    required this.attendances,
  });

  Map<String, dynamic> toJson() => {
        'course_id': courseId,
        'subject_id': subjectId,
        'date': date,
        'attendances': attendances.map((e) => e.toJson()).toList(),
      };
}

class BulkAttendanceEntry {
  final int studentId;
  final String status;
  final String? notes;

  const BulkAttendanceEntry({
    required this.studentId,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status': status,
        'notes': notes,
      };
}
