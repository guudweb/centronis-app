import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/assignments_service.dart';
import '../../models/assignment.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';

class TeacherAssignmentDetailScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const TeacherAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<TeacherAssignmentDetailScreen> createState() =>
      _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState
    extends ConsumerState<TeacherAssignmentDetailScreen> {
  Assignment? _assignment;
  List<Submission> _submissions = [];
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
        ref.read(assignmentsServiceProvider).getById(widget.assignmentId),
        ref.read(assignmentsServiceProvider).getSubmissions(widget.assignmentId),
      ]);
      setState(() {
        _assignment = (results[0] as dynamic).data;
        _submissions = results[1] as List<Submission>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showGradeDialog(Submission submission) {
    final gradeController =
        TextEditingController(text: submission.grade?.toStringAsFixed(0) ?? '');
    final feedbackController =
        TextEditingController(text: submission.feedback ?? '');
    final maxPoints = _assignment?.pointsPossible ?? 100;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Calificar - ${submission.studentName ?? 'Estudiante'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (submission.submissionText != null &&
                  submission.submissionText!.isNotEmpty) ...[
                Text('Respuesta del estudiante:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(submission.submissionText!,
                      style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calificación',
                  suffixText: '/ ${maxPoints.toStringAsFixed(0)}',
                  prefixIcon: const Icon(LucideIcons.star),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Retroalimentación (opcional)',
                  prefixIcon: Icon(LucideIcons.messageSquare),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final grade = double.tryParse(gradeController.text);
              if (grade == null) return;
              Navigator.pop(ctx);
              try {
                await ref.read(assignmentsServiceProvider).gradeSubmission(
                      widget.assignmentId,
                      submission.id,
                      grade: grade,
                      feedback: feedbackController.text.isNotEmpty
                          ? feedbackController.text
                          : null,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Calificación guardada'),
                      backgroundColor: AppTheme.successColor));
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Error al calificar'),
                      backgroundColor: AppTheme.errorColor));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_assignment?.title ?? 'Tarea')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando tarea...')
          : _assignment == null
              ? const Center(child: Text('Tarea no encontrada'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Assignment info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_assignment!.title,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(spacing: 12, runSpacing: 8, children: [
                                _infoBadge(LucideIcons.tag,
                                    _typeLabel(_assignment!.assignmentType)),
                                _infoBadge(LucideIcons.star,
                                    '${_assignment!.pointsPossible.toStringAsFixed(0)} pts'),
                                if (_assignment!.dueDate != null)
                                  _infoBadge(LucideIcons.calendar,
                                      AppDateUtils.formatDate(_assignment!.dueDate!)),
                                if (_assignment!.course != null)
                                  _infoBadge(LucideIcons.bookOpen,
                                      _assignment!.course!.name),
                              ]),
                              if (_assignment!.description != null &&
                                  _assignment!.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(_assignment!.description!,
                                    style: theme.textTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Submissions header
                      Row(children: [
                        const Icon(LucideIcons.users, size: 20),
                        const SizedBox(width: 8),
                        Text('Entregas (${_submissions.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _submissionSummary(),
                      ]),
                      const SizedBox(height: 8),

                      // Submissions list
                      if (_submissions.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text('No hay entregas aún',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                            ),
                          ),
                        )
                      else
                        ..._submissions.map((sub) => Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _statusColor(sub.status)
                                      .withValues(alpha: 0.15),
                                  child: Icon(_statusIcon(sub.status),
                                      size: 18,
                                      color: _statusColor(sub.status)),
                                ),
                                title: Text(
                                    sub.studentName ?? 'Estudiante #${sub.studentId}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                subtitle: Row(children: [
                                  Text(
                                      sub.submissionDate != null
                                          ? AppDateUtils.formatDate(
                                              sub.submissionDate!)
                                          : '',
                                      style: theme.textTheme.bodySmall),
                                  if (sub.isLate == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                          'Tarde${sub.lateDays != null ? ' (${sub.lateDays}d)' : ''}',
                                          style: const TextStyle(
                                              color: AppTheme.errorColor,
                                              fontSize: 10)),
                                    ),
                                  ],
                                ]),
                                trailing: sub.status == 'graded'
                                    ? Text(
                                        '${sub.grade?.toStringAsFixed(0) ?? '--'}/${_assignment!.pointsPossible.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              (sub.grade ?? 0) /
                                                          _assignment!
                                                              .pointsPossible >=
                                                      0.7
                                                  ? AppTheme.successColor
                                                  : AppTheme.errorColor,
                                        ),
                                      )
                                    : FilledButton.tonal(
                                        onPressed: () =>
                                            _showGradeDialog(sub),
                                        child: const Text('Calificar',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                onTap: sub.status == 'graded'
                                    ? () => _showGradeDialog(sub)
                                    : null,
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _submissionSummary() {
    final graded = _submissions.where((s) => s.status == 'graded').length;
    final pending = _submissions.length - graded;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$graded cal.',
            style: const TextStyle(
                color: AppTheme.successColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$pending pend.',
            style: const TextStyle(
                color: AppTheme.warningColor,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Color _statusColor(String status) {
    return switch (status) {
      'graded' => AppTheme.successColor,
      'submitted' => AppTheme.infoColor,
      'late' => AppTheme.warningColor,
      _ => Colors.grey,
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'graded' => LucideIcons.checkCircle,
      'submitted' => LucideIcons.send,
      'late' => LucideIcons.clock,
      _ => LucideIcons.circle,
    };
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
