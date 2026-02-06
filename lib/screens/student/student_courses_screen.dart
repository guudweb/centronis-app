import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/enrollments_service.dart';
import '../../services/schedule_service.dart';
import '../../services/teachers_service.dart' show ScheduleEntry;
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentCoursesScreen extends ConsumerStatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  ConsumerState<StudentCoursesScreen> createState() =>
      _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends ConsumerState<StudentCoursesScreen> {
  List<StudentEnrollment> _enrollments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final studentId = auth.user?.studentId;
      if (studentId == null) {
        setState(() => _loading = false);
        return;
      }
      final enrollments = await ref
          .read(enrollmentsServiceProvider)
          .getMyEnrollments(studentId: studentId);
      if (!mounted) return;
      setState(() {
        _enrollments = enrollments;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Curso')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando cursos...')
          : _enrollments.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.bookOpen,
                  title: 'Sin cursos',
                  description: 'No estás matriculado en ningún curso.')
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _enrollments.map((enrollment) {
                      return _courseCard(theme, enrollment);
                    }).toList(),
                  ),
                ),
    );
  }

  Widget _courseCard(ThemeData theme, StudentEnrollment enrollment) {
    final course = enrollment.course;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCourseDetail(enrollment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.bookOpen,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course?.name ?? 'Curso',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(course?.code ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (course?.level != null)
                      _badge(course!.level!, Colors.grey),
                    if (course?.section != null) ...[
                      const SizedBox(width: 6),
                      _badge('Sección ${course!.section!}', Colors.grey),
                    ],
                    if (enrollment.academicPeriod != null) ...[
                      const SizedBox(width: 6),
                      _badge(enrollment.academicPeriod!.name,
                          AppTheme.accentColor),
                    ],
                  ]),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18),
          ]),
        ),
      ),
    );
  }

  void _showCourseDetail(StudentEnrollment enrollment) {
    final courseId = enrollment.course?.id;
    if (courseId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => _CourseDetailSheet(
          courseId: courseId,
          courseName: enrollment.course?.name ?? 'Curso',
          scrollController: scrollController,
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}

class _CourseDetailSheet extends ConsumerStatefulWidget {
  final int courseId;
  final String courseName;
  final ScrollController scrollController;

  const _CourseDetailSheet({
    required this.courseId,
    required this.courseName,
    required this.scrollController,
  });

  @override
  ConsumerState<_CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends ConsumerState<_CourseDetailSheet> {
  List<ScheduleEntry> _schedule = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final entries = await ref
          .read(scheduleServiceProvider)
          .getAll(courseId: widget.courseId)
          .catchError((_) => <ScheduleEntry>[]);
      if (!mounted) return;
      setState(() {
        _schedule = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// Extract unique subjects from schedule entries
  List<({String name, String code})> get _uniqueSubjects {
    final seen = <int>{};
    final subjects = <({String name, String code})>[];
    for (final entry in _schedule) {
      final subj = entry.subject;
      if (subj != null && seen.add(subj.id)) {
        subjects.add((name: subj.name, code: subj.code));
      }
    }
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = _uniqueSubjects;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(widget.courseName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Subjects
                    if (subjects.isNotEmpty) ...[
                      _sectionTitle(
                          theme, LucideIcons.bookOpen, 'Asignaturas'),
                      const SizedBox(height: 8),
                      ...subjects.map((s) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.bookOpen,
                                    size: 18,
                                    color: AppTheme.primaryColor),
                              ),
                              title: Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: s.code.isNotEmpty
                                  ? Text(s.code,
                                      style: theme.textTheme.bodySmall)
                                  : null,
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Schedule
                    if (_schedule.isNotEmpty) ...[
                      _sectionTitle(
                          theme, LucideIcons.calendar, 'Horario'),
                      const SizedBox(height: 8),
                      ..._schedule.map((entry) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    _dayAbbr(entry.dayOfWeek),
                                    style: const TextStyle(
                                        color: AppTheme.accentColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                              title: Text(
                                  entry.subject?.name ?? 'Asignatura',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${entry.timeBlock?.startTime ?? ''} - ${entry.timeBlock?.endTime ?? ''}'
                                      .trim()),
                            ),
                          )),
                    ],

                    if (subjects.isEmpty && _schedule.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text('No hay información disponible',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  String _dayAbbr(int day) {
    return switch (day) {
      1 => 'LU',
      2 => 'MA',
      3 => 'MI',
      4 => 'JU',
      5 => 'VI',
      6 => 'SA',
      7 => 'DO',
      _ => '?',
    };
  }
}
