import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/assignments_service.dart';
import '../../services/teachers_service.dart';
import '../../models/assignment.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class TeacherAssignmentsScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends ConsumerState<TeacherAssignmentsScreen> {
  List<Assignment> _assignments = [];
  List<TeacherCourseSubject> _courses = [];
  int? _selectedCourseId;
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
      final courses = await ref
          .read(teachersServiceProvider)
          .getTeacherCourseSubjects(teacherId);
      setState(() {
        _courses = courses;
        _loading = false;
      });
      _loadAssignments();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final auth = ref.read(authProvider);
      final teacherId = auth.user?.teacherId;
      final result = await ref.read(assignmentsServiceProvider).getAll(
            teacherId: teacherId,
            courseId: _selectedCourseId,
            limit: 50,
            sort: '-created_at',
          );
      setState(() => _assignments = result.data);
    } catch (e) {
      // Keep existing list
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando tareas...')
          : Column(
              children: [
                // Course filter
                if (_courses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('Todos', _selectedCourseId == null,
                              () {
                            setState(() => _selectedCourseId = null);
                            _loadAssignments();
                          }),
                          ..._courses.map((cs) => _filterChip(
                                cs.courseName,
                                _selectedCourseId == cs.courseId,
                                () {
                                  setState(
                                      () => _selectedCourseId = cs.courseId);
                                  _loadAssignments();
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _assignments.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.clipboardList,
                          title: 'Sin tareas',
                          description: 'No hay tareas asignadas.')
                      : RefreshIndicator(
                          onRefresh: _loadAssignments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _assignments.length,
                            itemBuilder: (context, index) =>
                                _buildAssignmentCard(
                                    theme, _assignments[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildAssignmentCard(ThemeData theme, Assignment assignment) {
    final stats = assignment.submissionStats;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
            '/teacher/assignments/${assignment.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _typeIcon(assignment.assignmentType),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(assignment.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (!assignment.isPublished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Borrador',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                if (assignment.course != null)
                  Text(assignment.course!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w500)),
                const Spacer(),
                if (assignment.dueDate != null) ...[
                  Icon(LucideIcons.calendar, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(AppDateUtils.formatDate(assignment.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('${assignment.pointsPossible.toStringAsFixed(0)} pts',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text(
                    _typeLabel(assignment.assignmentType),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                if (stats != null) ...[
                  _submissionBadge(
                      '${stats.graded}', AppTheme.successColor, 'Calificadas'),
                  const SizedBox(width: 8),
                  _submissionBadge(
                      '${stats.pending}', AppTheme.warningColor, 'Pendientes'),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    final (icon, color) = switch (type) {
      'homework' => (LucideIcons.home, AppTheme.primaryColor),
      'project' => (LucideIcons.folder, AppTheme.accentColor),
      'exam' => (LucideIcons.fileText, AppTheme.errorColor),
      'quiz' => (LucideIcons.helpCircle, AppTheme.warningColor),
      'presentation' => (LucideIcons.presentation, AppTheme.infoColor),
      _ => (LucideIcons.clipboardList, Colors.grey),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'homework' => 'Tarea',
      'project' => 'Proyecto',
      'exam' => 'Examen',
      'quiz' => 'Quiz',
      'presentation' => 'Presentación',
      'report' => 'Reporte',
      _ => type,
    };
  }

  Widget _submissionBadge(String count, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
            child: Text(count,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color))),
      ),
    ]);
  }
}
