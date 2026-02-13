import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart' show authProvider;
import '../../services/announcements_service.dart';
import '../../services/assignments_service.dart';
import '../../services/enrollments_service.dart';
import '../../services/schedule_service.dart';
import '../../services/teachers_service.dart' show ScheduleEntry;
import '../../services/events_service.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  List<dynamic> _announcements = [];
  List<dynamic> _assignments = [];
  List<dynamic> _schedule = [];
  List<dynamic> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final studentId = auth.user?.studentId;

      final results = await Future.wait([
        ref
            .read(announcementsServiceProvider)
            .getAll(page: 1, limit: 5)
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        ref
            .read(assignmentsServiceProvider)
            .getAll(page: 1, limit: 5)
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        // Load today's schedule via enrollments (GET /schedules is admin-only)
        _loadTodaySchedule(studentId),
        ref
            .read(eventsServiceProvider)
            .getAll(
              startDate: AppDateUtils.toIso(DateTime.now()),
              endDate: AppDateUtils.toIso(
                  DateTime.now().add(const Duration(days: 30))),
            )
            .then<dynamic>((r) => r)
            .catchError((_) => null),
      ]);

      if (!mounted) return;
      setState(() {
        if (results[0] != null) {
          _announcements = (results[0] as dynamic).data ?? [];
        }
        if (results[1] != null) {
          _assignments = (results[1] as dynamic).data ?? [];
        }
        if (results[2] != null) {
          _schedule = results[2] as List<dynamic>;
        }
        if (results[3] != null) {
          _events = results[3] is List ? results[3] as List<dynamic> : [];
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Load today's schedule using enrollment-based approach
  /// (GET /schedules/course/:id is accessible to students)
  Future<List<ScheduleEntry>> _loadTodaySchedule(int? studentId) async {
    if (studentId == null) return [];
    try {
      final enrollments = await ref
          .read(enrollmentsServiceProvider)
          .getMyEnrollments(studentId: studentId, status: 'active');

      final todayEntries = <ScheduleEntry>[];
      final today = DateTime.now().weekday;

      for (final enrollment in enrollments) {
        final courseId = enrollment.course?.id;
        if (courseId == null) continue;
        try {
          final courseSchedule = await ref
              .read(scheduleServiceProvider)
              .getCourseSchedule(courseId);
          final todayClasses = courseSchedule[today];
          if (todayClasses != null) {
            todayEntries.addAll(todayClasses);
          }
        } catch (_) {}
      }

      todayEntries.sort((a, b) =>
          (a.timeBlock?.startTime ?? '')
              .compareTo(b.timeBlock?.startTime ?? ''));
      return todayEntries;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Panel')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Hola, ${auth.user?.firstName ?? ''}',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),

                  // Quick access cards
                  Row(children: [
                    Expanded(
                      child: _quickAccessCard(
                        theme,
                        'Tareas',
                        _assignments.isEmpty
                            ? 'Sin tareas pendientes'
                            : '${_assignments.length} pendiente${_assignments.length == 1 ? '' : 's'}',
                        LucideIcons.clipboardList,
                        AppTheme.warningColor,
                        () => context.go('/student/assignments'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickAccessCard(
                        theme,
                        'Boletín',
                        'Ver calificaciones',
                        LucideIcons.graduationCap,
                        AppTheme.primaryColor,
                        () => context.go('/student/grades/report-card'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Upcoming classes (today's schedule)
                  _sectionHeader(theme, 'Próximas clases', LucideIcons.clock),
                  const SizedBox(height: 8),
                  if (_schedule.isEmpty)
                    _emptyCard(theme, 'No hay clases programadas')
                  else
                    ..._schedule.take(4).map((s) => _scheduleCard(theme, s)),
                  const SizedBox(height: 24),

                  // Announcements
                  _sectionHeader(
                      theme, 'Anuncios recientes', LucideIcons.megaphone),
                  const SizedBox(height: 8),
                  if (_announcements.isEmpty)
                    _emptyCard(theme, 'No hay anuncios')
                  else
                    ..._announcements.map((a) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.megaphone,
                                  size: 18, color: AppTheme.primaryColor),
                            ),
                            title: Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                AppDateUtils.relativeTime(a.createdAt),
                                style: theme.textTheme.bodySmall),
                          ),
                        )),
                  const SizedBox(height: 24),

                  // Calendar / upcoming events
                  _sectionHeader(
                      theme, 'Próximos eventos', LucideIcons.calendarDays),
                  const SizedBox(height: 8),
                  if (_events.isEmpty)
                    _emptyCard(theme, 'No hay eventos próximos')
                  else
                    ..._events.take(3).map((e) => _eventCard(theme, e)),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _quickAccessCard(ThemeData theme, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard(ThemeData theme, dynamic entry) {
    // Handle both map and object schedule entries
    String subject = '';
    String time = '';
    String teacher = '';
    if (entry is Map<String, dynamic>) {
      subject = entry['subject']?['name'] as String? ??
          entry['subject_name'] as String? ??
          'Clase';
      time = entry['time_block']?['start_time'] as String? ??
          entry['start_time'] as String? ??
          '';
      final endTime = entry['time_block']?['end_time'] as String? ??
          entry['end_time'] as String? ??
          '';
      if (time.isNotEmpty && endTime.isNotEmpty) {
        time = '$time - $endTime';
      }
      teacher = entry['teacher']?['user']?['first_name'] as String? ?? '';
    } else {
      try {
        subject = (entry as dynamic).subjectName ?? 'Clase';
        time = '${(entry as dynamic).startTime ?? ''} - ${(entry as dynamic).endTime ?? ''}';
        teacher = (entry as dynamic).teacherName ?? '';
      } catch (_) {
        subject = 'Clase';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.clock, size: 18, color: AppTheme.accentColor),
        ),
        title: Text(subject,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            [if (time.isNotEmpty) time, if (teacher.isNotEmpty) teacher]
                .join(' - '),
            style: theme.textTheme.bodySmall),
      ),
    );
  }

  Widget _eventCard(ThemeData theme, dynamic event) {
    String title = '';
    String date = '';
    String type = '';
    if (event is Map<String, dynamic>) {
      title = event['title'] as String? ?? '';
      date = event['start_date'] as String? ?? '';
      type = event['event_type'] as String? ?? '';
    } else {
      try {
        title = (event as dynamic).title ?? '';
        date = (event as dynamic).startDate ?? '';
        type = (event as dynamic).eventType ?? '';
      } catch (_) {}
    }
    final color = switch (type) {
      'holiday' => Colors.red,
      'exam' => Colors.amber.shade700,
      'meeting' => Colors.blue,
      'activity' => Colors.green,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.calendarDays, size: 18, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: date.isNotEmpty
            ? Text(AppDateUtils.formatDate(date),
                style: theme.textTheme.bodySmall)
            : null,
      ),
    );
  }

  Widget _emptyCard(ThemeData theme, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}
