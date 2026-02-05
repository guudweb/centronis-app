import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/teachers_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class TeacherCoursesScreen extends ConsumerStatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  ConsumerState<TeacherCoursesScreen> createState() =>
      _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends ConsumerState<TeacherCoursesScreen> {
  List<TeacherCourseSubject> _courseSubjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final teacherId = auth.user?.teacherId;
      if (teacherId == null) {
        setState(() => _loading = false);
        return;
      }
      final courses = await ref
          .read(teachersServiceProvider)
          .getTeacherCourseSubjects(teacherId);
      setState(() {
        _courseSubjects = courses;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <int, List<TeacherCourseSubject>>{};
    for (final cs in _courseSubjects) {
      grouped.putIfAbsent(cs.courseId, () => []).add(cs);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cursos')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando cursos...')
          : grouped.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.bookOpen,
                  title: 'Sin cursos asignados',
                  description: 'No tienes cursos asignados en este período.')
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final courseId = grouped.keys.elementAt(index);
                      final subjects = grouped[courseId]!;
                      final courseName = subjects.first.courseName;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                            '/teacher/courses/$courseId?name=${Uri.encodeComponent(courseName)}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.bookOpen,
                                      size: 20, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(courseName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600)),
                                ),
                                Text(
                                    '${subjects.length} materia${subjects.length == 1 ? '' : 's'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant)),
                              ]),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              ...subjects.map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(children: [
                                      Icon(LucideIcons.layers,
                                          size: 16,
                                          color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(s.subjectName)),
                                      if (s.isPrimary)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
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
                                        ),
                                    ]),
                                  )),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
