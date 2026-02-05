import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import 'teachers_service.dart';

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ScheduleService(dioClient.dio);
});

class ScheduleService {
  final Dio _dio;

  ScheduleService(this._dio);

  /// Get schedule for a specific course grouped by day
  Future<Map<int, List<ScheduleEntry>>> getCourseSchedule(
      int courseId) async {
    final response = await _dio.get('/schedules/course/$courseId');
    final data = response.data as Map<String, dynamic>;
    final rawData = data['data'];

    final result = <int, List<ScheduleEntry>>{};

    if (rawData is Map<String, dynamic>) {
      rawData.forEach((key, value) {
        final dayNum = int.tryParse(key) ?? 0;
        final entries = (value as List<dynamic>)
            .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        if (entries.isNotEmpty) {
          result[dayNum] = entries;
        }
      });
    } else if (rawData is List<dynamic>) {
      for (final entry in rawData) {
        final scheduleEntry =
            ScheduleEntry.fromJson(entry as Map<String, dynamic>);
        result
            .putIfAbsent(scheduleEntry.dayOfWeek, () => [])
            .add(scheduleEntry);
      }
    }

    return result;
  }

  /// Get all schedules with optional filters
  Future<List<ScheduleEntry>> getAll({
    int? courseId,
    int? teacherId,
    int? dayOfWeek,
    int? academicPeriodId,
  }) async {
    final response = await _dio.get('/schedules', queryParameters: {
      if (courseId != null) 'courseId': courseId,
      if (teacherId != null) 'teacherId': teacherId,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      if (academicPeriodId != null) 'academicPeriodId': academicPeriodId,
    });
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
