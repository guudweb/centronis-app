import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/enrollments_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentCoursesScreen extends ConsumerStatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  ConsumerState<StudentCoursesScreen> createState() =>
      _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends ConsumerState<StudentCoursesScreen> {
  List<StudentEnrollment> _enrollments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _loading = true);
    try {
      final auth = ref.read(authProvider);
      final studentId = auth.user?.studentId;
      if (studentId == null) {
        setState(() => _loading = false);
        return;
      }
      final enrollments = await ref
          .read(enrollmentsServiceProvider)
          .getMyEnrollments(studentId: studentId);
      setState(() {
        _enrollments = enrollments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final active =
        _enrollments.where((e) => e.status == 'active' || e.status == 'enrolled').toList();
    final completed =
        _enrollments.where((e) => e.status == 'completed').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Cursos')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando cursos...')
          : _enrollments.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.bookOpen,
                  title: 'Sin cursos',
                  description: 'No estás matriculado en ningún curso.')
              : RefreshIndicator(
                  onRefresh: _loadEnrollments,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary
                      Row(children: [
                        Expanded(
                            child: _summaryCard(theme, 'Total',
                                '${_enrollments.length}', AppTheme.primaryColor)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _summaryCard(theme, 'Activos',
                                '${active.length}', AppTheme.successColor)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _summaryCard(theme, 'Completados',
                                '${completed.length}', AppTheme.infoColor)),
                      ]),
                      const SizedBox(height: 20),

                      if (active.isNotEmpty) ...[
                        Text('Cursos activos',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...active.map((e) => _courseCard(theme, e)),
                        const SizedBox(height: 16),
                      ],

                      if (completed.isNotEmpty) ...[
                        Text('Completados',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...completed.map((e) => _courseCard(theme, e)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _summaryCard(ThemeData theme, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _courseCard(ThemeData theme, StudentEnrollment enrollment) {
    final course = enrollment.course;
    final isActive =
        enrollment.status == 'active' || enrollment.status == 'enrolled';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isActive ? AppTheme.primaryColor : AppTheme.infoColor)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.bookOpen,
                color: isActive ? AppTheme.primaryColor : AppTheme.infoColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course?.name ?? 'Curso',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(course?.code ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(children: [
                  if (course?.level != null)
                    _badge(course!.level!, Colors.grey),
                  if (course?.section != null) ...[
                    const SizedBox(width: 6),
                    _badge('Sección ${course!.section!}', Colors.grey),
                  ],
                  if (enrollment.academicPeriod != null) ...[
                    const SizedBox(width: 6),
                    _badge(enrollment.academicPeriod!.name,
                        AppTheme.accentColor),
                  ],
                ]),
              ],
            ),
          ),
          _statusChip(enrollment.status),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'active' || 'enrolled' => ('Activo', AppTheme.successColor),
      'completed' => ('Completado', AppTheme.infoColor),
      'withdrawn' => ('Retirado', AppTheme.errorColor),
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
