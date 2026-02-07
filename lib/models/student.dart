class Student {
  final int id;
  final int userId;
  final String studentCode;
  final String admissionDate;
  final String? guardian1Name;
  final String? guardian1Phone;
  final String? guardian1Email;
  final String? guardian1Relationship;
  final String? guardian2Name;
  final String? guardian2Phone;
  final String? guardian2Email;
  final String? guardian2Relationship;
  final String? medicalInfo;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? notes;
  final String status;
  final String createdAt;
  final String updatedAt;
  final StudentUser? user;
  final int? activeEnrollments;

  const Student({
    required this.id,
    required this.userId,
    required this.studentCode,
    required this.admissionDate,
    this.guardian1Name,
    this.guardian1Phone,
    this.guardian1Email,
    this.guardian1Relationship,
    this.guardian2Name,
    this.guardian2Phone,
    this.guardian2Email,
    this.guardian2Relationship,
    this.medicalInfo,
    this.emergencyContact,
    this.emergencyPhone,
    this.notes,
    this.status = 'active',
    this.createdAt = '',
    this.updatedAt = '',
    this.user,
    this.activeEnrollments,
  });

  String get fullName =>
      user != null ? '${user!.firstName} ${user!.lastName}' : '';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  /// Safely convert dynamic to String? (handles Maps, ints, etc.)
  static String? _toStr(dynamic v) =>
      v == null ? null : (v is String ? v : null);

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      studentCode: _toStr(json['student_code']) ?? '',
      admissionDate: _toStr(json['admission_date']) ?? '',
      guardian1Name: _toStr(json['guardian1_name']),
      guardian1Phone: _toStr(json['guardian1_phone']),
      guardian1Email: _toStr(json['guardian1_email']),
      guardian1Relationship: _toStr(json['guardian1_relationship']),
      guardian2Name: _toStr(json['guardian2_name']),
      guardian2Phone: _toStr(json['guardian2_phone']),
      guardian2Email: _toStr(json['guardian2_email']),
      guardian2Relationship: _toStr(json['guardian2_relationship']),
      medicalInfo: _toStr(json['medical_info']),
      emergencyContact: _toStr(json['emergency_contact']),
      emergencyPhone: _toStr(json['emergency_phone']),
      notes: _toStr(json['notes']),
      status: _toStr(json['status']) ?? 'active',
      createdAt: _toStr(json['created_at']) ?? '',
      updatedAt: _toStr(json['updated_at']) ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? StudentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      activeEnrollments: json['active_enrollments'] != null ? _toInt(json['active_enrollments']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_data': {
          'email': user?.email,
          'first_name': user?.firstName,
          'last_name': user?.lastName,
          'document_type': user?.documentType,
          'document_number': user?.documentNumber,
          'phone': user?.phone,
          'address': user?.address,
          'birth_date': user?.birthDate,
          'gender': user?.gender,
        },
        'student_data': {
          'student_code': studentCode,
          'admission_date': admissionDate,
          'guardian1_name': guardian1Name,
          'guardian1_phone': guardian1Phone,
          'guardian1_email': guardian1Email,
          'guardian1_relationship': guardian1Relationship,
          'medical_info': medicalInfo,
          'emergency_contact': emergencyContact,
          'emergency_phone': emergencyPhone,
          'notes': notes,
          'status': status,
        },
      };
}

class StudentUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? documentType;
  final String? documentNumber;
  final String? phone;
  final String? address;
  final String? birthDate;
  final String? gender;
  final String? profileImageUrl;
  final bool active;

  const StudentUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.documentType,
    this.documentNumber,
    this.phone,
    this.address,
    this.birthDate,
    this.gender,
    this.profileImageUrl,
    this.active = true,
  });

  String get fullName => '$firstName $lastName';

  static String? _toStr(dynamic v) =>
      v == null ? null : (v is String ? v : null);

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      email: _toStr(json['email']) ?? '',
      firstName: _toStr(json['first_name']) ?? '',
      lastName: _toStr(json['last_name']) ?? '',
      documentType: _toStr(json['document_type']),
      documentNumber: _toStr(json['document_number']),
      phone: _toStr(json['phone']),
      address: _toStr(json['address']),
      birthDate: _toStr(json['birth_date']),
      gender: _toStr(json['gender']),
      profileImageUrl: _toStr(json['profile_image_url']),
      active: json['active'] as bool? ?? true,
    );
  }
}

class StudentSearchResult {
  final int id;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String email;
  final String fullName;

  const StudentSearchResult({
    required this.id,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.fullName,
  });

  factory StudentSearchResult.fromJson(Map<String, dynamic> json) {
    return StudentSearchResult(
      id: json['id'] as int,
      studentCode: json['student_code'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
    );
  }
}
