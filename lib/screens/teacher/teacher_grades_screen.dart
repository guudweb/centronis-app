import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/teachers_service.dart';
import '../../services/enrollments_service.dart';
import '../../services/grades_service.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';

class TeacherGradesScreen extends ConsumerStatefulWidget {
  const TeacherGradesScreen({super.key});

  @override
  ConsumerState<TeacherGradesScreen> createState() =>
      _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends ConsumerState<TeacherGradesScreen> {
  List<TeacherCourseSubject> _courses = [];
  TeacherCourseSubject? _selectedCourse;
  List<EnrolledStudent> _students = [];
  Map<int, TextEditingController> _gradeControllers = {};
  String _gradeType = 'exam';
  final _maxGradeController = TextEditingController(text: '100');
  bool _loadingCourses = true;
  bool _loadingStudents = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _maxGradeController.dispose();
    for (final c in _gradeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final auth = ref.read(authProvider);
      final teacherId = auth.user?.teacherId;
      if (teacherId == null) {
        setState(() => _loadingCourses = false);
        return;
      }
      final courses = await ref
          .read(teachersServiceProvider)
          .getTeacherCourseSubjects(teacherId);
      setState(() {
        _courses = courses;
        _loadingCourses = false;
      });
    } catch (e) {
      setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    setState(() => _loadingStudents = true);
    try {
      final students = await ref
          .read(enrollmentsServiceProvider)
          .getCourseEnrollments(_selectedCourse!.courseId);
      for (final c in _gradeControllers.values) {
        c.dispose();
      }
      final controllers = <int, TextEditingController>{};
      for (final s in students) {
        controllers[s.studentId] = TextEditingController();
      }
      setState(() {
        _students = students;
        _gradeControllers = controllers;
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveGrades() async {
    if (_selectedCourse == null || _students.isEmpty) return;
    final grades = <Map<String, dynamic>>[];
    for (final student in _students) {
      final controller = _gradeControllers[student.studentId];
      if (controller != null && controller.text.isNotEmpty) {
        final value = double.tryParse(controller.text);
        if (value != null) {
          grades.add({'student_id': student.studentId, 'grade_value': value});
        }
      }
    }
    if (grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay calificaciones para guardar')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(gradesServiceProvider).createBulk({
        'course_id': _selectedCourse!.courseId,
        'subject_id': _selectedCourse!.subjectId,
        'grade_type': _gradeType,
        'max_grade': double.tryParse(_maxGradeController.text) ?? 100,
        'weight': 1.0,
        'graded_date': AppDateUtils.toIso(DateTime.now()),
        'grades': grades,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Calificaciones guardadas correctamente'),
            backgroundColor: AppTheme.successColor));
        for (final c in _gradeControllers.values) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error al guardar calificaciones'),
            backgroundColor: AppTheme.errorColor));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones'),
        actions: [
          if (_students.isNotEmpty)
            TextButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.save, size: 18),
              label: const Text('Guardar'),
              onPressed: _saving ? null : _saveGrades,
            ),
        ],
      ),
      body: _loadingCourses
          ? const LoadingWidget(message: 'Cargando cursos...')
          : Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  DropdownButtonFormField<TeacherCourseSubject>(
                    initialValue: _selectedCourse,
                    decoration: const InputDecoration(
                        labelText: 'Curso y materia',
                        prefixIcon: Icon(LucideIcons.bookOpen)),
                    items: _courses
                        .map((cs) => DropdownMenuItem(
                            value: cs,
                            child: Text(
                                '${cs.courseName} - ${cs.subjectName}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourse = value);
                      _loadStudents();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gradeType,
                        decoration: const InputDecoration(
                            labelText: 'Tipo',
                            prefixIcon: Icon(LucideIcons.tag)),
                        items: const [
                          DropdownMenuItem(value: 'exam', child: Text('Examen')),
                          DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                          DropdownMenuItem(
                              value: 'assignment', child: Text('Tarea')),
                          DropdownMenuItem(
                              value: 'participation',
                              child: Text('Participación')),
                          DropdownMenuItem(
                              value: 'project', child: Text('Proyecto')),
                          DropdownMenuItem(
                              value: 'midterm', child: Text('Parcial')),
                          DropdownMenuItem(value: 'final', child: Text('Final')),
                        ],
                        onChanged: (v) => setState(() => _gradeType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _maxGradeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Máx.',
                            prefixIcon: Icon(LucideIcons.hash)),
                      ),
                    ),
                  ]),
                ]),
              ),
              Expanded(
                child: _loadingStudents
                    ? const LoadingWidget(message: 'Cargando estudiantes...')
                    : _students.isEmpty
                        ? Center(
                            child: Text(
                                _selectedCourse == null
                                    ? 'Selecciona un curso'
                                    : 'No hay estudiantes matriculados',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)))
                        : ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final controller =
                                  _gradeControllers[student.studentId]!;
                              return ListTile(
                                leading: CircleAvatar(
                                    radius: 18,
                                    child: Text(
                                        student.fullName.isNotEmpty
                                            ? student.fullName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(fontSize: 14))),
                                title: Text(student.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Text(student.studentCode),
                                trailing: SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                        hintText: '0',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8)),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ]),
    );
  }
}
