class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final int roleId;
  final String? roleCode;
  final int? institutionId;
  final bool active;
  final bool emailVerified;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final String? birthDate;
  final String? gender;
  final String? profileImageUrl;
  final String? address;
  final Role? role;
  final InstitutionRef? institution;
  final int? studentId;
  final int? teacherId;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roleId,
    this.roleCode,
    this.institutionId,
    this.active = true,
    this.emailVerified = false,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.birthDate,
    this.gender,
    this.profileImageUrl,
    this.address,
    this.role,
    this.institution,
    this.studentId,
    this.teacherId,
  });

  String get fullName => '$firstName $lastName';

  String get roleName => role?.name ?? roleCode ?? '';

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  static int? _toIntNullable(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      roleId: _toInt(json['role_id']),
      roleCode: json['role_code'] as String?,
      institutionId: _toIntNullable(json['institution_id']),
      active: json['active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      phone: json['phone'] as String?,
      documentType: json['document_type'] as String?,
      documentNumber: json['document_number'] as String?,
      birthDate: json['birth_date'] as String?,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      address: json['address'] as String?,
      role: json['role'] != null
          ? Role.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      institution: json['institution'] != null
          ? InstitutionRef.fromJson(
              json['institution'] as Map<String, dynamic>)
          : null,
      studentId: _toIntNullable(json['student_id']),
      teacherId: _toIntNullable(json['teacher_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role_id': roleId,
        'role_code': roleCode,
        'institution_id': institutionId,
        'active': active,
        'phone': phone,
        'document_type': documentType,
        'document_number': documentNumber,
        'birth_date': birthDate,
        'gender': gender,
        'address': address,
      };
}

class Role {
  final int id;
  final String name;
  final String code;
  final List<String>? permissions;

  const Role({
    required this.id,
    required this.name,
    required this.code,
    this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class InstitutionRef {
  final int id;
  final String name;
  final String code;
  final String? timezone;
  final String? currency;

  const InstitutionRef({
    required this.id,
    required this.name,
    required this.code,
    this.timezone,
    this.currency,
  });

  factory InstitutionRef.fromJson(Map<String, dynamic> json) {
    return InstitutionRef(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      timezone: json['timezone'] as String?,
      currency: json['currency'] as String?,
    );
  }
}
