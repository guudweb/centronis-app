import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/grades_service.dart';
import '../../services/attendance_service.dart';
import '../../services/announcements_service.dart';
import '../../models/grade.dart';
import '../../models/attendance.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../core/utils/date_utils.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  GradeSummary? _gradeSummary;
  List<AttendanceReport> _attendanceReport = [];
  List<dynamic> _announcements = [];
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
      if (studentId == null) {
        setState(() => _loading = false);
        return;
      }

      final results = await Future.wait([
        ref.read(gradesServiceProvider).getStudentSummary(studentId),
        ref.read(attendanceServiceProvider).getReport(studentId: studentId),
        ref.read(announcementsServiceProvider).getAll(page: 1, limit: 5),
      ]);

      setState(() {
        final gradeResponse = results[0] as dynamic;
        _gradeSummary = gradeResponse.data;

        final attendanceResponse = results[1] as dynamic;
        _attendanceReport =
            (attendanceResponse.data as List<AttendanceReport>?) ?? [];

        final announcementsResponse = results[2] as dynamic;
        _announcements = announcementsResponse.data;
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

    // Calculate attendance percentage
    double attendancePercent = 0;
    if (_attendanceReport.isNotEmpty) {
      attendancePercent = _attendanceReport.first.attendanceRate;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Panel'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
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
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        StatCard(
                          title: 'Promedio',
                          value: _gradeSummary != null
                              ? _gradeSummary!.gpa.toStringAsFixed(1)
                              : '--',
                          icon: LucideIcons.trendingUp,
                          color: AppTheme.primaryColor,
                        ),
                        StatCard(
                          title: 'Asistencia',
                          value: '${attendancePercent.toStringAsFixed(0)}%',
                          icon: LucideIcons.clipboardCheck,
                          color: AppTheme.successColor,
                        ),
                        StatCard(
                          title: 'Cursos',
                          value: _gradeSummary != null
                              ? '${_gradeSummary!.courses.length}'
                              : '--',
                          icon: LucideIcons.bookOpen,
                          color: AppTheme.accentColor,
                        ),
                        StatCard(
                          title: 'Anuncios',
                          value: '${_announcements.length}',
                          icon: LucideIcons.megaphone,
                          color: AppTheme.warningColor,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 32),

                  // Course averages
                  if (_gradeSummary != null &&
                      _gradeSummary!.courses.isNotEmpty) ...[
                    Text('Mis promedios por curso',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._gradeSummary!.courses.map((course) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  course.overallAverage.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: course.overallAverage >= 70
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(course.courseName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(course.courseCode),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Recent announcements
                  Text('Anuncios recientes',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_announcements.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text('No hay anuncios',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                    )
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
                ],
              ),
            ),
    );
  }
}
