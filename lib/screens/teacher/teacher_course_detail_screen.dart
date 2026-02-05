import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/enrollments_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class TeacherCourseDetailScreen extends ConsumerStatefulWidget {
  final int courseId;
  final String courseName;
  const TeacherCourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseName = 'Curso',
  });

  @override
  ConsumerState<TeacherCourseDetailScreen> createState() =>
      _TeacherCourseDetailScreenState();
}

class _TeacherCourseDetailScreenState
    extends ConsumerState<TeacherCourseDetailScreen> {
  List<EnrolledStudent> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final students = await ref
          .read(enrollmentsServiceProvider)
          .getCourseEnrollments(widget.courseId);
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<EnrolledStudent> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students
        .where((s) =>
            s.fullName.toLowerCase().contains(q) ||
            s.studentCode.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredStudents;

    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      body: _loading
          ? const LoadingWidget(message: 'Cargando estudiantes...')
          : Column(
              children: [
                // Course info + quick actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.15),
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
                                Text(widget.courseName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                Text(
                                    '${_students.length} estudiantes matriculados',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick actions
                    Row(children: [
                      Expanded(
                          child: _actionButton(
                              context,
                              LucideIcons.clipboardCheck,
                              'Asistencia',
                              AppTheme.successColor,
                              () => context.go('/teacher/attendance'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _actionButton(
                              context,
                              LucideIcons.fileText,
                              'Notas',
                              AppTheme.primaryColor,
                              () => context.go('/teacher/grades'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _actionButton(
                              context,
                              LucideIcons.clipboardList,
                              'Tareas',
                              AppTheme.warningColor,
                              () => context.go('/teacher/assignments'))),
                    ]),
                    const SizedBox(height: 12),
                    // Search
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar estudiante...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ]),
                ),
                // Student list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Text('Estudiantes (${filtered.length})',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                  ]),
                ),
                const SizedBox(height: 8),
                // Student list
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.users,
                          title: 'Sin estudiantes',
                          description: 'No hay estudiantes en este curso.')
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = filtered[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primaryColor
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    student.fullName.isNotEmpty
                                        ? student.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                title: Text(student.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(student.studentCode),
                                trailing: Text(student.email ?? '',
                                    style: theme.textTheme.bodySmall),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
