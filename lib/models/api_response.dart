class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message'] is String ? json['message'] as String : '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final List<T> data;
  final Pagination pagination;
  final List<String>? errors;

  const PaginatedResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
    this.errors,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      success: json['success'] == true,
      message: json['message'] is String ? json['message'] as String : '',
      data: (json['data'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  static int _toInt(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: _toInt(json['page'], 1),
      limit: _toInt(json['limit'], 10),
      total: _toInt(json['total']),
      totalPages: _toInt(json['totalPages']),
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }
}
