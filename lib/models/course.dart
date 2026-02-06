class Course {
  final int id;
  final String name;
  final String code;
  final String? level;
  final String? section;
  final int? capacity;
  final int academicPeriodId;
  final int? gradeScaleId;
  final int institutionId;
  final bool active;
  final String createdAt;
  final String updatedAt;
  final AcademicPeriodRef? academicPeriod;
  final GradeScaleRef? gradeScale;
  final int? enrolledStudents;

  const Course({
    required this.id,
    required this.name,
    required this.code,
    this.level,
    this.section,
    this.capacity,
    required this.academicPeriodId,
    this.gradeScaleId,
    required this.institutionId,
    this.active = true,
    this.createdAt = '',
    this.updatedAt = '',
    this.academicPeriod,
    this.gradeScale,
    this.enrolledStudents,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  static int? _toIntNullable(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      level: json['level'] as String?,
      section: json['section'] as String?,
      capacity: _toIntNullable(json['capacity']),
      academicPeriodId: _toInt(json['academic_period_id']),
      gradeScaleId: _toIntNullable(json['grade_scale_id']),
      institutionId: _toInt(json['institution_id']),
      active: json['active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      academicPeriod: json['academic_period'] != null
          ? AcademicPeriodRef.fromJson(
              json['academic_period'] as Map<String, dynamic>)
          : null,
      gradeScale: json['grade_scale'] != null
          ? GradeScaleRef.fromJson(
              json['grade_scale'] as Map<String, dynamic>)
          : null,
      enrolledStudents: _toIntNullable(json['enrolled_students']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'level': level,
        'section': section,
        'capacity': capacity,
        'academic_period_id': academicPeriodId,
        'grade_scale_id': gradeScaleId,
      };
}

class AcademicPeriodRef {
  final int id;
  final String name;
  final String code;
  final String type;
  final String startDate;
  final String endDate;
  final bool isCurrent;

  const AcademicPeriodRef({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
  });

  factory AcademicPeriodRef.fromJson(Map<String, dynamic> json) {
    return AcademicPeriodRef(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }
}

class GradeScaleRef {
  final int id;
  final String name;
  final String type;

  const GradeScaleRef({
    required this.id,
    required this.name,
    required this.type,
  });

  factory GradeScaleRef.fromJson(Map<String, dynamic> json) {
    return GradeScaleRef(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}
