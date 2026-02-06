import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../services/courses_service.dart';
import '../../models/course.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class CoursesManagementScreen extends ConsumerStatefulWidget {
  const CoursesManagementScreen({super.key});

  @override
  ConsumerState<CoursesManagementScreen> createState() =>
      _CoursesManagementScreenState();
}

class _CoursesManagementScreenState
    extends ConsumerState<CoursesManagementScreen> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref.read(coursesServiceProvider).getAll(
            page: page,
            limit: 20,
          );
      setState(() {
        _courses = response.data;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Error al cargar cursos';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos'),
      ),
      body: _loading
          ? const LoadingWidget(message: 'Cargando cursos...')
          : _error != null
              ? EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: 'Error',
                  description: _error,
                  actionLabel: 'Reintentar',
                  onAction: _loadCourses,
                )
              : _courses.isEmpty
                  ? const EmptyState(
                      icon: LucideIcons.bookOpen,
                      title: 'Sin cursos',
                      description: 'Crea un curso para comenzar.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCourses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    course.code,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                course.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                [
                                  if (course.level != null) course.level!,
                                  if (course.section != null) course.section!,
                                  if (course.academicPeriod != null)
                                    course.academicPeriod!.name,
                                ].join(' - '),
                              ),
                              trailing: Text(
                                '${course.enrolledStudents ?? 0} est.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              onTap: () => context.push(
                                  '/admin/courses/${course.id}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
