import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/teachers_service.dart';
import '../../services/enrollments_service.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TeacherCourseSubject> _courses = [];
  TeacherCourseSubject? _selectedCourse;
  List<EnrolledStudent> _students = [];
  Map<int, String> _attendanceStatus = {};
  bool _loadingCourses = true;
  bool _loadingStudents = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
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
      final statusMap = <int, String>{};
      for (final s in students) {
        statusMap[s.studentId] = 'present';
      }
      setState(() {
        _students = students;
        _attendanceStatus = statusMap;
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedCourse == null || _students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = BulkAttendanceData(
        courseId: _selectedCourse!.courseId,
        subjectId: _selectedCourse!.subjectId,
        date: AppDateUtils.toIso(_selectedDate),
        attendances: _students
            .map((s) => BulkAttendanceEntry(
                  studentId: s.studentId,
                  status: _attendanceStatus[s.studentId] ?? 'present',
                ))
            .toList(),
      );
      await ref.read(attendanceServiceProvider).bulkMark(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Asistencia guardada correctamente'),
              backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar la asistencia'),
              backgroundColor: AppTheme.errorColor),
        );
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
        title: const Text('Asistencia'),
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
              onPressed: _saving ? null : _saveAttendance,
            ),
        ],
      ),
      body: _loadingCourses
          ? const LoadingWidget(message: 'Cargando cursos...')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.calendar, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              AppDateUtils.formatDate(
                                  _selectedDate.toIso8601String()),
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourse != null
                          ? '${_selectedCourse!.courseId}_${_selectedCourse!.subjectId}'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar curso y materia',
                        prefixIcon: Icon(LucideIcons.bookOpen),
                      ),
                      items: _courses
                          .map((cs) => DropdownMenuItem(
                              value: '${cs.courseId}_${cs.subjectId}',
                              child: Text(
                                  '${cs.courseName} - ${cs.subjectName}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final parts = value.split('_');
                          final cId = int.tryParse(parts[0]);
                          final sId = int.tryParse(parts[1]);
                          setState(() => _selectedCourse = _courses.firstWhere(
                              (cs) => cs.courseId == cId && cs.subjectId == sId));
                        }
                        _loadStudents();
                      },
                    ),
                  ]),
                ),
                Expanded(
                  child: _loadingStudents
                      ? const LoadingWidget(message: 'Cargando estudiantes...')
                      : _students.isEmpty
                          ? Center(
                              child: Text(
                                  _selectedCourse == null
                                      ? 'Selecciona un curso para marcar asistencia'
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
                                final status =
                                    _attendanceStatus[student.studentId] ??
                                        'present';
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(student.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14)),
                                      const SizedBox(height: 6),
                                      SegmentedButton<String>(
                                        segments: const [
                                          ButtonSegment(
                                              value: 'present',
                                              label: Text('P', style: TextStyle(fontSize: 12)),
                                              icon: Icon(LucideIcons.check,
                                                  size: 14)),
                                          ButtonSegment(
                                              value: 'absent',
                                              label: Text('A', style: TextStyle(fontSize: 12)),
                                              icon: Icon(LucideIcons.x,
                                                  size: 14)),
                                          ButtonSegment(
                                              value: 'late',
                                              label: Text('T', style: TextStyle(fontSize: 12)),
                                              icon: Icon(LucideIcons.clock,
                                                  size: 14)),
                                          ButtonSegment(
                                              value: 'excused',
                                              label: Text('E', style: TextStyle(fontSize: 12)),
                                              icon: Icon(
                                                  LucideIcons.shieldCheck,
                                                  size: 14)),
                                        ],
                                        selected: {status},
                                        onSelectionChanged: (sel) =>
                                            setState(() =>
                                                _attendanceStatus[
                                                        student.studentId] =
                                                    sel.first),
                                        showSelectedIcon: false,
                                        style: ButtonStyle(
                                          visualDensity: VisualDensity.compact,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding:
                                              const WidgetStatePropertyAll(
                                                  EdgeInsets.symmetric(
                                                      horizontal: 4)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                if (_students.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                          top: BorderSide(
                              color: theme.colorScheme.outlineVariant)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _chip('Presentes',
                            _attendanceStatus.values.where((s) => s == 'present').length,
                            AppTheme.successColor),
                        _chip('Ausentes',
                            _attendanceStatus.values.where((s) => s == 'absent').length,
                            AppTheme.errorColor),
                        _chip('Tardanza',
                            _attendanceStatus.values.where((s) => s == 'late').length,
                            AppTheme.warningColor),
                        _chip('Excusado',
                            _attendanceStatus.values.where((s) => s == 'excused').length,
                            AppTheme.infoColor),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$count',
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ]);
  }
}
