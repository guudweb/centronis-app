class Announcement {
  final int id;
  final String title;
  final String content;
  final String? type;
  final int authorId;
  final int institutionId;
  final String? targetAudience;
  final String priority;
  final int? courseId;
  final bool published;
  final String? publishDate;
  final String? expiryDate;
  final String createdAt;
  final String updatedAt;
  final AnnouncementAuthor? author;
  final AnnouncementCourseRef? course;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.type,
    required this.authorId,
    required this.institutionId,
    this.targetAudience,
    this.priority = 'normal',
    this.courseId,
    this.published = true,
    this.publishDate,
    this.expiryDate,
    this.createdAt = '',
    this.updatedAt = '',
    this.author,
    this.course,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  static int? _toIntNullable(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: _toInt(json['id']),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String?,
      authorId: _toInt(json['author_id']),
      institutionId: _toInt(json['institution_id']),
      targetAudience: json['target_audience'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      courseId: _toIntNullable(json['course_id']),
      published: json['published'] as bool? ?? true,
      publishDate: json['publish_date'] as String?,
      expiryDate: json['expiry_date'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      author: json['author'] != null
          ? AnnouncementAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      course: json['course'] != null
          ? AnnouncementCourseRef.fromJson(
              json['course'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'type': type,
        'target_audience': targetAudience,
        'course_id': courseId,
        'published': published,
        'publish_date': publishDate,
        'expiry_date': expiryDate,
      };
}

class AnnouncementAuthor {
  final int id;
  final String firstName;
  final String lastName;

  const AnnouncementAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';
  String get name => fullName;

  factory AnnouncementAuthor.fromJson(Map<String, dynamic> json) {
    return AnnouncementAuthor(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
    );
  }
}

class AnnouncementCourseRef {
  final int id;
  final String name;

  const AnnouncementCourseRef({required this.id, required this.name});

  factory AnnouncementCourseRef.fromJson(Map<String, dynamic> json) {
    return AnnouncementCourseRef(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}
