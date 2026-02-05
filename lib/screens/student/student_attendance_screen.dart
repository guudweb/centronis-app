import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../core/utils/date_utils.dart';

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends ConsumerState<StudentAttendanceScreen> {
  List<AttendanceReport> _report = [];
  List<Attendance> _recentAttendance = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final studentId = auth.user?.studentId;
      if (studentId == null) {
        setState(() => _loading = false);
        return;
      }

      final results = await Future.wait([
        ref.read(attendanceServiceProvider).getReport(studentId: studentId),
        ref
            .read(attendanceServiceProvider)
            .getByStudent(studentId),
      ]);

      setState(() {
        _report =
            (results[0] as dynamic).data as List<AttendanceReport>? ?? [];
        _recentAttendance =
            (results[1] as dynamic).data as List<Attendance>? ?? [];
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
      appBar: AppBar(title: const Text('Mi Asistencia')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando asistencia...')
          : _report.isEmpty && _recentAttendance.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.clipboardCheck,
                  title: 'Sin registros',
                  description: 'No hay registros de asistencia.')
              : RefreshIndicator(
                  onRefresh: _loadAttendance,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary cards
                      if (_report.isNotEmpty) ...[
                        Text('Resumen',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._report.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (r.courseName != null)
                                      Text(r.courseName!,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    // Attendance bar
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: r.attendanceRate / 100,
                                        minHeight: 8,
                                        backgroundColor: theme.colorScheme
                                            .surfaceContainerHighest,
                                        valueColor:
                                            AlwaysStoppedAnimation(
                                          r.attendanceRate >= 80
                                              ? AppTheme.successColor
                                              : r.attendanceRate >= 60
                                                  ? AppTheme.warningColor
                                                  : AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _statBadge('Presente',
                                            r.presentCount, AppTheme.successColor),
                                        _statBadge('Ausente',
                                            r.absentCount, AppTheme.errorColor),
                                        _statBadge('Tardanza',
                                            r.lateCount, AppTheme.warningColor),
                                        _statBadge('Excusado',
                                            r.excusedCount, AppTheme.infoColor),
                                        Text(
                                          '${r.attendanceRate.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: r.attendanceRate >= 80
                                                ? AppTheme.successColor
                                                : AppTheme.errorColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      // Recent records
                      if (_recentAttendance.isNotEmpty) ...[
                        Text('Registros recientes',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._recentAttendance.take(20).map((a) => Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                dense: true,
                                leading: _statusIcon(a.status),
                                title: Text(
                                    a.course?.name ?? 'Curso',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle:
                                    Text(AppDateUtils.formatDate(a.date)),
                                trailing: _statusChip(a.status),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$count',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: color, fontSize: 16)),
      Text(label, style: TextStyle(fontSize: 10, color: color)),
    ]);
  }

  Widget _statusIcon(String status) {
    final (icon, color) = switch (status) {
      'present' => (LucideIcons.checkCircle, AppTheme.successColor),
      'absent' => (LucideIcons.xCircle, AppTheme.errorColor),
      'late' => (LucideIcons.clock, AppTheme.warningColor),
      'excused' => (LucideIcons.shieldCheck, AppTheme.infoColor),
      _ => (LucideIcons.circle, Colors.grey),
    };
    return Icon(icon, color: color, size: 22);
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'present' => ('Presente', AppTheme.successColor),
      'absent' => ('Ausente', AppTheme.errorColor),
      'late' => ('Tardanza', AppTheme.warningColor),
      'excused' => ('Excusado', AppTheme.infoColor),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
