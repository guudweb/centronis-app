import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/courses_service.dart';
import '../../services/schedule_service.dart';
import '../../services/teachers_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentScheduleScreen extends ConsumerStatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  ConsumerState<StudentScheduleScreen> createState() =>
      _StudentScheduleScreenState();
}

class _StudentScheduleScreenState
    extends ConsumerState<StudentScheduleScreen> {
  Map<int, List<ScheduleEntry>> _schedule = {};
  bool _loading = true;

  static const _dayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      // Get student's courses first, then get schedule for each course
      final auth = ref.read(authProvider);
      final studentId = auth.user?.studentId;
      if (studentId == null) {
        setState(() => _loading = false);
        return;
      }

      // Get student's enrolled courses
      final coursesResponse =
          await ref.read(coursesServiceProvider).getAll(limit: 50);
      final allSchedule = <int, List<ScheduleEntry>>{};

      for (final course in coursesResponse.data) {
        try {
          final courseSchedule = await ref
              .read(scheduleServiceProvider)
              .getCourseSchedule(course.id);
          courseSchedule.forEach((day, entries) {
            allSchedule.putIfAbsent(day, () => []).addAll(entries);
          });
        } catch (_) {
          // Skip courses without schedule
        }
      }

      // Sort entries by time within each day
      allSchedule.forEach((day, entries) {
        entries.sort((a, b) =>
            (a.timeBlock?.startTime ?? '').compareTo(b.timeBlock?.startTime ?? ''));
      });

      setState(() {
        _schedule = allSchedule;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayDay = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Horario')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando horario...')
          : _schedule.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.calendar,
                  title: 'Sin horario',
                  description: 'No hay horario disponible.')
              : RefreshIndicator(
                  onRefresh: _loadSchedule,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (int day = 1; day <= 7; day++)
                        if (_schedule.containsKey(day)) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16, bottom: 8),
                            child: Row(children: [
                              Text(
                                _dayNames[day] ?? 'Día $day',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (day == todayDay) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Hoy',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ]),
                          ),
                          ...(_schedule[day] ?? []).map((entry) => Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: day == todayDay
                                          ? AppTheme.primaryColor
                                              .withValues(alpha: 0.1)
                                          : theme.colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          entry.timeBlock?.startTime
                                                  .substring(0, 5) ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: day == todayDay
                                                ? AppTheme.primaryColor
                                                : theme.colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          entry.timeBlock?.endTime
                                                  .substring(0, 5) ??
                                              '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                      entry.subject?.name ?? 'Materia',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      '${entry.course?.name ?? ''} ${entry.classroom != null ? '- Aula ${entry.classroom}' : ''}'),
                                ),
                              )),
                        ],
                    ],
                  ),
                ),
    );
  }
}
