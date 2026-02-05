import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/grades_service.dart';
import '../../models/grade.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class ParentChildReportCardScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildReportCardScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildReportCardScreen> createState() =>
      _ParentChildReportCardScreenState();
}

class _ParentChildReportCardScreenState
    extends ConsumerState<ParentChildReportCardScreen> {
  GradeSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(gradesServiceProvider)
          .getStudentSummary(widget.studentId);
      setState(() {
        _summary = result.data;
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
      appBar: AppBar(title: const Text('Boletín')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando boletín...')
          : _summary == null
              ? const EmptyState(
                  icon: LucideIcons.graduationCap,
                  title: 'Sin datos',
                  description: 'No hay información del boletín.')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Card(
                        color: AppTheme.primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('Promedio General',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _summary!.gpa.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '${_summary!.courses.length} cursos',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _summary!.gpa >= 70
                                        ? 'Aprobado'
                                        : 'En riesgo',
                                    style: TextStyle(
                                      color: _summary!.gpa >= 70
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Table
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        margin: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Expanded(
                                flex: 3,
                                child: Text('Curso',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w700))),
                            Expanded(
                                child: Text('Prom.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w700))),
                            Expanded(
                                child: Text('Estado',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w700))),
                          ]),
                        ),
                      ),
                      ..._summary!.courses.asMap().entries.map((entry) {
                        final course = entry.value;
                        final isLast =
                            entry.key ==
                                _summary!.courses.length - 1;
                        final passed = course.overallAverage >= 70;
                        return Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: isLast
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(12))
                                : BorderRadius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(course.courseName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(course.courseCode,
                                        style: theme
                                            .textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (passed
                                              ? AppTheme.successColor
                                              : AppTheme.errorColor)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      course.overallAverage
                                          .toStringAsFixed(1),
                                      style: TextStyle(
                                        color: passed
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    passed
                                        ? LucideIcons.checkCircle
                                        : LucideIcons.alertCircle,
                                    color: passed
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _legendItem(
                                  AppTheme.successColor, 'Aprobado (≥70)'),
                              _legendItem(
                                  AppTheme.errorColor, 'En riesgo (<70)'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
