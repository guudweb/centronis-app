class Grade {
  final int id;
  final int studentId;
  final int courseId;
  final int? subjectId;
  final int academicPeriodId;
  final String gradeType;
  final int? assignmentId;
  final double gradeValue;
  final double maxGrade;
  final double? maxValue;
  final double weight;
  final double? percentage;
  final String? letterGrade;
  final int? gradeScaleId;
  final String? comments;
  final bool isFinal;
  final int gradedBy;
  final String gradedDate;
  final int institutionId;
  final String createdAt;
  final String updatedAt;
  final GradeStudentRef? student;
  final GradeCourseRef? course;
  final GradeSubjectRef? subject;

  const Grade({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.subjectId,
    required this.academicPeriodId,
    required this.gradeType,
    this.assignmentId,
    required this.gradeValue,
    required this.maxGrade,
    this.maxValue,
    this.weight = 1.0,
    this.percentage,
    this.letterGrade,
    this.gradeScaleId,
    this.comments,
    this.isFinal = false,
    required this.gradedBy,
    required this.gradedDate,
    required this.institutionId,
    this.createdAt = '',
    this.updatedAt = '',
    this.student,
    this.course,
    this.subject,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;
  static int? _toIntNullable(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: _toInt(json['id']),
      studentId: _toInt(json['student_id']),
      courseId: _toInt(json['course_id']),
      subjectId: _toIntNullable(json['subject_id']),
      academicPeriodId: _toInt(json['academic_period_id']),
      gradeType: json['grade_type'] as String? ?? '',
      assignmentId: _toIntNullable(json['assignment_id']),
      gradeValue: (json['grade_value'] as num?)?.toDouble() ?? 0,
      maxGrade: (json['max_grade'] as num?)?.toDouble() ?? 100.0,
      maxValue: (json['max_value'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      percentage: (json['percentage'] as num?)?.toDouble(),
      letterGrade: json['letter_grade'] as String?,
      gradeScaleId: _toIntNullable(json['grade_scale_id']),
      comments: json['comments'] as String?,
      isFinal: json['is_final'] as bool? ?? false,
      gradedBy: _toInt(json['graded_by']),
      gradedDate: json['graded_date'] as String? ?? '',
      institutionId: _toInt(json['institution_id']),
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      student: json['student'] != null
          ? GradeStudentRef.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      course: json['course'] != null
          ? GradeCourseRef.fromJson(json['course'] as Map<String, dynamic>)
          : null,
      subject: json['subject'] != null
          ? GradeSubjectRef.fromJson(json['subject'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'course_id': courseId,
        'subject_id': subjectId,
        'academic_period_id': academicPeriodId,
        'grade_type': gradeType,
        'assignment_id': assignmentId,
        'grade_value': gradeValue,
        'max_grade': maxGrade,
        'weight': weight,
        'comments': comments,
        'graded_date': gradedDate,
      };
}

class GradeStudentRef {
  final int id;
  final String firstName;
  final String lastName;
  final String studentCode;
  final String? email;

  const GradeStudentRef({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentCode,
    this.email,
  });

  String get fullName => '$firstName $lastName';

  factory GradeStudentRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return GradeStudentRef(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}

class GradeCourseRef {
  final int id;
  final String name;
  final String code;

  const GradeCourseRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory GradeCourseRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return GradeCourseRef(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class GradeSubjectRef {
  final int id;
  final String name;
  final String code;

  const GradeSubjectRef({
    required this.id,
    required this.name,
    required this.code,
  });

  factory GradeSubjectRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return GradeSubjectRef(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class GradeSummary {
  final GradeStudentRef student;
  final List<CourseSummary> courses;
  final double gpa;

  const GradeSummary({
    required this.student,
    required this.courses,
    required this.gpa,
  });

  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    return GradeSummary(
      student: json['student'] is Map<String, dynamic>
          ? GradeStudentRef.fromJson(json['student'] as Map<String, dynamic>)
          : const GradeStudentRef(
              id: 0, firstName: '', lastName: '', studentCode: ''),
      courses: json['courses'] is List
          ? (json['courses'] as List<dynamic>)
              .map((e) => CourseSummary.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CourseSummary {
  final int courseId;
  final String courseName;
  final String courseCode;
  final double overallAverage;

  const CourseSummary({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.overallAverage,
  });

  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    final cid = json['course_id'];
    return CourseSummary(
      courseId: cid is int ? cid : int.tryParse(cid?.toString() ?? '') ?? 0,
      courseName: json['course_name'] as String? ?? '',
      courseCode: json['course_code'] as String? ?? '',
      overallAverage: (json['overall_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
