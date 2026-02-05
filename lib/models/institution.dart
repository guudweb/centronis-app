class Institution {
  final int id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool active;

  const Institution({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.active = true,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}
