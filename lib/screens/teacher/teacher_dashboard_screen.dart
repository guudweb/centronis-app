import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/teachers_service.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/loading_widget.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  List<TeacherCourseSubject> _courses = [];
  Map<int, List<ScheduleEntry>> _schedule = {};
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
      final teacherId = auth.user?.teacherId;
      if (teacherId == null) {
        setState(() => _loading = false);
        return;
      }

      final teachersService = ref.read(teachersServiceProvider);
      final results = await Future.wait([
        teachersService.getTeacherCourseSubjects(teacherId),
        teachersService.getTeacherSchedule(teacherId),
      ]);

      setState(() {
        _courses = results[0] as List<TeacherCourseSubject>;
        _schedule = results[1] as Map<int, List<ScheduleEntry>>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final todayDay = DateTime.now().weekday;
    final todayEntries = _schedule[todayDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Profesor'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Cargando panel...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Hola, ${auth.user?.firstName ?? ''}',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 3 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        StatCard(
                          title: 'Mis cursos',
                          value: '${_courses.map((c) => c.courseId).toSet().length}',
                          icon: LucideIcons.bookOpen,
                          color: AppTheme.primaryColor,
                        ),
                        StatCard(
                          title: 'Materias',
                          value: '${_courses.length}',
                          icon: LucideIcons.layers,
                          color: AppTheme.secondaryColor,
                        ),
                        StatCard(
                          title: 'Clases hoy',
                          value: '${todayEntries.length}',
                          icon: LucideIcons.calendar,
                          color: AppTheme.accentColor,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),
                  Text('Clases de hoy',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (todayEntries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('No tienes clases programadas para hoy',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    )
                  else
                    ...todayEntries.map((entry) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  entry.timeBlock?.startTime.substring(0, 5) ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                            title: Text(entry.subject?.name ?? 'Materia',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${entry.course?.name ?? ''} ${entry.classroom != null ? '- Aula ${entry.classroom}' : ''}'),
                            trailing: Text(
                              '${entry.timeBlock?.startTime.substring(0, 5) ?? ''} - ${entry.timeBlock?.endTime.substring(0, 5) ?? ''}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        )),
                  const SizedBox(height: 32),
                  Text('Mis cursos y materias',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_courses.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('No tienes cursos asignados',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    )
                  else
                    ..._courses.map((cs) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.bookOpen,
                                  size: 18, color: AppTheme.accentColor),
                            ),
                            title: Text(cs.subjectName,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(cs.courseName),
                            trailing: cs.isPrimary
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Principal',
                                        style: TextStyle(
                                            color: AppTheme.successColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  )
                                : null,
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
