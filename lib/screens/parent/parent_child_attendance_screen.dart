import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class ParentChildAttendanceScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildAttendanceScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildAttendanceScreen> createState() =>
      _ParentChildAttendanceScreenState();
}

class _ParentChildAttendanceScreenState
    extends ConsumerState<ParentChildAttendanceScreen> {
  List<AttendanceReport> _reports = [];
  List<Attendance> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ref
            .read(attendanceServiceProvider)
            .getReport(studentId: widget.studentId),
        ref
            .read(attendanceServiceProvider)
            .getByStudent(widget.studentId),
      ]);
      setState(() {
        final reportResp = results[0] as dynamic;
        _reports = (reportResp.data as List<AttendanceReport>?) ?? [];
        final recentResp = results[1] as dynamic;
        _recent = (recentResp.data as List<Attendance>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double overallPercent = 0;
    if (_reports.isNotEmpty) {
      overallPercent = _reports.first.attendanceRate;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando asistencia...')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overall summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Text('Asistencia General',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Text(
                          '${overallPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: overallPercent >= 80
                                ? AppTheme.successColor
                                : overallPercent >= 60
                                    ? AppTheme.warningColor
                                    : AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: overallPercent / 100,
                            minHeight: 10,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              overallPercent >= 80
                                  ? AppTheme.successColor
                                  : overallPercent >= 60
                                      ? AppTheme.warningColor
                                      : AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Per course
                  if (_reports.isNotEmpty) ...[
                    Text('Por curso',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._reports.map((report) {
                      final rate = report.attendanceRate;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                child: Text(report.courseName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text('${rate.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: rate >= 80
                                        ? AppTheme.successColor
                                        : rate >= 60
                                            ? AppTheme.warningColor
                                            : AppTheme.errorColor,
                                  )),
                            ]),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rate / 100,
                                minHeight: 6,
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  rate >= 80
                                      ? AppTheme.successColor
                                      : rate >= 60
                                          ? AppTheme.warningColor
                                          : AppTheme.errorColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _miniStat('P', report.presentCount,
                                    AppTheme.successColor),
                                _miniStat('A', report.absentCount,
                                    AppTheme.errorColor),
                                _miniStat('T', report.lateCount,
                                    AppTheme.warningColor),
                                _miniStat('E', report.excusedCount,
                                    AppTheme.infoColor),
                              ],
                            ),
                          ]),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Recent records
                  if (_recent.isNotEmpty) ...[
                    Text('Registros recientes',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._recent.map((a) => Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: _statusIcon(a.status),
                            title: Text(a.courseName ?? 'Curso',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(AppDateUtils.formatDate(a.date)),
                            trailing: _statusLabel(a.status),
                          ),
                        )),
                  ],

                  if (_reports.isEmpty && _recent.isEmpty)
                    const EmptyState(
                      icon: LucideIcons.clipboardCheck,
                      title: 'Sin registros',
                      description: 'No hay registros de asistencia.',
                    ),
                ],
              ),
            ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text('$label: $count', style: TextStyle(fontSize: 11, color: color)),
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
    return Icon(icon, color: color, size: 20);
  }

  Widget _statusLabel(String status) {
    final (label, color) = switch (status) {
      'present' => ('Presente', AppTheme.successColor),
      'absent' => ('Ausente', AppTheme.errorColor),
      'late' => ('Tardanza', AppTheme.warningColor),
      'excused' => ('Excusado', AppTheme.infoColor),
      _ => (status, Colors.grey),
    };
    return Text(label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600));
  }
}
