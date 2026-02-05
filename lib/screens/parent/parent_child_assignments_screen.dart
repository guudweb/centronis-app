import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/parent_portal_service.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class ParentChildAssignmentsScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildAssignmentsScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildAssignmentsScreen> createState() =>
      _ParentChildAssignmentsScreenState();
}

class _ParentChildAssignmentsScreenState
    extends ConsumerState<ParentChildAssignmentsScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(parentPortalServiceProvider)
          .getChildAssignments(widget.studentId, limit: 30);
      final data = result['data'];
      if (data is List) {
        setState(() {
          _assignments =
              data.map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
      } else if (data is Map && data['assignments'] is List) {
        setState(() {
          _assignments = (data['assignments'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando tareas...')
          : _assignments.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.clipboardList,
                  title: 'Sin tareas',
                  description: 'No hay tareas registradas.')
              : RefreshIndicator(
                  onRefresh: _loadAssignments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) =>
                        _buildCard(theme, _assignments[index]),
                  ),
                ),
    );
  }

  Widget _buildCard(ThemeData theme, Map<String, dynamic> assignment) {
    final title = assignment['title'] as String? ?? 'Tarea';
    final type = assignment['assignment_type'] as String? ?? '';
    final dueDate = assignment['due_date'] as String?;
    final pointsPossible =
        (assignment['points_possible'] as num?)?.toDouble() ?? 0;
    final course = assignment['course'] as Map<String, dynamic>?;
    final submission = assignment['my_submission'] as Map<String, dynamic>?;
    final status = submission?['status'] as String?;
    final grade = (submission?['grade'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _typeIcon(type),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              _statusBadge(status),
            ]),
            const SizedBox(height: 8),
            if (course != null)
              Text(course['name'] as String? ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(children: [
              if (pointsPossible > 0) ...[
                Icon(LucideIcons.star,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${pointsPossible.toStringAsFixed(0)} pts',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
              ],
              if (dueDate != null) ...[
                Icon(LucideIcons.calendar,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(AppDateUtils.formatDate(dueDate),
                    style: theme.textTheme.bodySmall),
              ],
              const Spacer(),
              if (grade != null)
                Text(
                  '${grade.toStringAsFixed(0)}/${pointsPossible.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: pointsPossible > 0 &&
                            grade / pointsPossible >= 0.7
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
            ]),
          ],
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

  Widget _statusBadge(String? status) {
    if (status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Pendiente',
            style: TextStyle(
                color: AppTheme.warningColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
    }
    final (label, color) = switch (status) {
      'graded' => ('Calificada', AppTheme.successColor),
      'submitted' => ('Entregada', AppTheme.infoColor),
      'late' => ('Tarde', AppTheme.warningColor),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
