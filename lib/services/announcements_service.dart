import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/announcement.dart';

final announcementsServiceProvider = Provider<AnnouncementsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AnnouncementsService(dioClient.dio);
});

class AnnouncementsService {
  final Dio _dio;

  AnnouncementsService(this._dio);

  Future<PaginatedResponse<Announcement>> getAll({
    int? page,
    int? limit,
    String? type,
    int? courseId,
  }) async {
    final response = await _dio.get('/announcements', queryParameters: {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (type != null) 'type': type,
      if (courseId != null) 'course_id': courseId,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Announcement.fromJson,
    );
  }

  Future<ApiResponse<Announcement>> getById(int id) async {
    final response = await _dio.get('/announcements/$id');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Announcement.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Announcement>> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/announcements', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Announcement.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Announcement>> update(
      int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/announcements/$id', data: data);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Announcement.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete('/announcements/$id');
  }
}
