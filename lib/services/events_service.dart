import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../models/event.dart';

final eventsServiceProvider = Provider<EventsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return EventsService(dioClient.dio);
});

class EventsService {
  final Dio _dio;

  EventsService(this._dio);

  Future<List<CalendarEvent>> getAll({
    String? eventType,
    String? startDate,
    String? endDate,
    int? academicPeriodId,
    int? page,
    int? limit,
  }) async {
    final response = await _dio.get('/events', queryParameters: {
      if (eventType != null) 'event_type': eventType,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (academicPeriodId != null) 'academic_period_id': academicPeriodId,
      if (page != null) 'page': page,
      'limit': limit ?? 100,
    });
    final data = response.data as Map<String, dynamic>;
    final nested = data['data'];
    final list = (nested is Map ? nested['events'] : nested)
        as List<dynamic>? ??
        [];
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarEvent>> getUpcoming() async {
    final response = await _dio.get('/events/upcoming');
    final data = response.data as Map<String, dynamic>;
    final nested = data['data'];
    final list = (nested is Map ? (nested['events'] ?? nested) : nested)
        as List<dynamic>? ??
        [];
    return list
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
