import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/assignments_service.dart';
import '../../models/assignment.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentAssignmentsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  ConsumerState<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends ConsumerState<StudentAssignmentsScreen> {
  List<Assignment> _assignments = [];
  bool _loading = true;
  String _filter = 'all'; // all, pending, submitted, graded

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(assignmentsServiceProvider).getAll(
            limit: 50,
            isPublished: true,
            sort: '-due_date',
          );
      setState(() {
        _assignments = result.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Assignment> get _filteredAssignments {
    if (_filter == 'all') return _assignments;
    return _assignments.where((a) {
      final status = a.mySubmission?.status;
      return switch (_filter) {
        'pending' => status == null,
        'submitted' => status == 'submitted' || status == 'late',
        'graded' => status == 'graded',
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredAssignments;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando tareas...')
          : Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    children: [
                      _filterChip('Todas', 'all'),
                      _filterChip('Pendientes', 'pending'),
                      _filterChip('Entregadas', 'submitted'),
                      _filterChip('Calificadas', 'graded'),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.clipboardList,
                          title: 'Sin tareas',
                          description: 'No hay tareas para mostrar.')
                      : RefreshIndicator(
                          onRefresh: _loadAssignments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildCard(theme, filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, Assignment assignment) {
    final sub = assignment.mySubmission;
    final isPastDue = assignment.dueDate != null &&
        DateTime.tryParse(assignment.dueDate!)
                ?.isBefore(DateTime.now()) ==
            true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAssignmentDetail(assignment),
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
                _submissionStatus(sub, isPastDue),
              ]),
              const SizedBox(height: 8),
              if (assignment.course != null)
                Text(
                    '${assignment.course!.name}${assignment.subject != null ? ' - ${assignment.subject!.name}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(LucideIcons.star, size: 14,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${assignment.pointsPossible.toStringAsFixed(0)} pts',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                if (assignment.dueDate != null) ...[
                  Icon(LucideIcons.calendar,
                      size: 14,
                      color: isPastDue && sub == null
                          ? AppTheme.errorColor
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(AppDateUtils.formatDate(assignment.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: isPastDue && sub == null
                              ? AppTheme.errorColor
                              : null)),
                ],
                const Spacer(),
                if (sub?.status == 'graded')
                  Text(
                    '${sub!.grade?.toStringAsFixed(0) ?? '--'}/${assignment.pointsPossible.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: (sub.grade ?? 0) / assignment.pointsPossible >= 0.7
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetail(Assignment assignment) {
    final sub = assignment.mySubmission;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Header
                Row(children: [
                  Expanded(
                    child: Text(assignment.title,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.x)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  _infoBadge(LucideIcons.tag,
                      _typeLabel(assignment.assignmentType)),
                  _infoBadge(LucideIcons.star,
                      '${assignment.pointsPossible.toStringAsFixed(0)} pts'),
                  if (assignment.dueDate != null)
                    _infoBadge(LucideIcons.calendar,
                        AppDateUtils.formatDate(assignment.dueDate!)),
                  if (assignment.course != null)
                    _infoBadge(
                        LucideIcons.bookOpen, assignment.course!.name),
                ]),
                if (assignment.description != null &&
                    assignment.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Descripción',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(assignment.description!),
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Submission section
                if (sub != null) ...[
                  Text('Mi entrega',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Card(
                    color: _statusColor(sub.status)
                        .withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _submissionStatus(sub, false),
                            const Spacer(),
                            if (sub.submissionDate != null)
                              Text(
                                  AppDateUtils.formatDate(
                                      sub.submissionDate!),
                                  style: theme.textTheme.bodySmall),
                          ]),
                          if (sub.submissionText != null &&
                              sub.submissionText!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(sub.submissionText!),
                          ],
                          if (sub.status == 'graded') ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Text('Calificación: ',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              Text(
                                '${sub.grade?.toStringAsFixed(1) ?? '--'}/${assignment.pointsPossible.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: (sub.grade ?? 0) /
                                              assignment.pointsPossible >=
                                          0.7
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                              ),
                            ]),
                            if (sub.feedback != null &&
                                sub.feedback!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Retroalimentación:',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(sub.feedback!),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Submit form
                  Text('Entregar tarea',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu respuesta aquí...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (textController.text.isEmpty) return;
                        try {
                          await ref
                              .read(assignmentsServiceProvider)
                              .submit(
                                assignment.id,
                                submissionText: textController.text,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadAssignments();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Tarea entregada'),
                                    backgroundColor:
                                        AppTheme.successColor));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error al entregar'),
                                    backgroundColor:
                                        AppTheme.errorColor));
                          }
                        }
                      },
                      icon: const Icon(LucideIcons.send),
                      label: const Text('Entregar'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
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

  Widget _submissionStatus(Submission? sub, bool isPastDue) {
    if (sub == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (isPastDue ? AppTheme.errorColor : AppTheme.warningColor)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isPastDue ? 'Vencida' : 'Pendiente',
          style: TextStyle(
            color: isPastDue ? AppTheme.errorColor : AppTheme.warningColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final (label, color) = switch (sub.status) {
      'graded' => ('Calificada', AppTheme.successColor),
      'submitted' => ('Entregada', AppTheme.infoColor),
      'late' => ('Entregada tarde', AppTheme.warningColor),
      _ => (sub.status, Colors.grey),
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

  Color _statusColor(String status) {
    return switch (status) {
      'graded' => AppTheme.successColor,
      'submitted' => AppTheme.infoColor,
      'late' => AppTheme.warningColor,
      _ => Colors.grey,
    };
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
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
}
