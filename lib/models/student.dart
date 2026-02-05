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

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      studentCode: json['student_code'] as String? ?? '',
      admissionDate: json['admission_date'] as String? ?? '',
      guardian1Name: json['guardian1_name'] as String?,
      guardian1Phone: json['guardian1_phone'] as String?,
      guardian1Email: json['guardian1_email'] as String?,
      guardian1Relationship: json['guardian1_relationship'] as String?,
      guardian2Name: json['guardian2_name'] as String?,
      guardian2Phone: json['guardian2_phone'] as String?,
      guardian2Email: json['guardian2_email'] as String?,
      guardian2Relationship: json['guardian2_relationship'] as String?,
      medicalInfo: json['medical_info'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      user: json['user'] != null
          ? StudentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      activeEnrollments: json['active_enrollments'] as int?,
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

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
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
