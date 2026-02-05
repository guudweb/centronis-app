import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/grades_service.dart';
import '../../models/grade.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class ParentChildGradesScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildGradesScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildGradesScreen> createState() =>
      _ParentChildGradesScreenState();
}

class _ParentChildGradesScreenState
    extends ConsumerState<ParentChildGradesScreen> {
  GradeSummary? _summary;
  List<Grade> _grades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ref.read(gradesServiceProvider).getStudentSummary(widget.studentId),
        ref.read(gradesServiceProvider).getAll(
              studentId: widget.studentId,
              limit: 50,
            ),
      ]);
      setState(() {
        _summary = (results[0] as dynamic).data;
        _grades = (results[1] as dynamic).data as List<Grade>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calificaciones')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando calificaciones...')
          : _summary == null
              ? const EmptyState(
                  icon: LucideIcons.fileText,
                  title: 'Sin calificaciones',
                  description: 'No hay calificaciones registradas.')
              : RefreshIndicator(
                  onRefresh: _loadGrades,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary
                      Card(
                        color: AppTheme.primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Promedio General',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  _summary!.gpa.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${_summary!.courses.length} cursos',
                                    style: const TextStyle(
                                        color: Colors.white70)),
                                Text('${_grades.length} notas',
                                    style: const TextStyle(
                                        color: Colors.white70)),
                              ],
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // By course
                      ..._summary!.courses.map((course) {
                        final courseGrades = _grades
                            .where((g) => g.courseId == course.courseId)
                            .toList();
                        final passed = course.overallAverage >= 70;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(course.courseName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (passed
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  course.overallAverage.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: passed
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            ...courseGrades.map((grade) => Card(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                        _gradeTypeLabel(grade.gradeType),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    subtitle: grade.subject != null
                                        ? Text(grade.subject!.name)
                                        : null,
                                    trailing: Text(
                                      '${grade.gradeValue.toStringAsFixed(0)}/${grade.maxGrade.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: grade.gradeValue /
                                                    grade.maxGrade >=
                                                0.7
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                      ),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  String _gradeTypeLabel(String type) {
    return switch (type) {
      'exam' => 'Examen',
      'quiz' => 'Quiz',
      'assignment' => 'Tarea',
      'participation' => 'Participación',
      'midterm' => 'Parcial',
      'final' => 'Final',
      'project' => 'Proyecto',
      _ => type,
    };
  }
}
