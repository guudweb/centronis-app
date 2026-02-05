import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/parent_portal_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../core/utils/date_utils.dart';

class ParentChildrenScreen extends ConsumerStatefulWidget {
  const ParentChildrenScreen({super.key});

  @override
  ConsumerState<ParentChildrenScreen> createState() =>
      _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends ConsumerState<ParentChildrenScreen> {
  List<ParentChild> _children = [];
  ParentChildDetail? _selectedChildDetail;
  int? _selectedChildId;
  bool _loadingList = true;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _loadingList = true);
    try {
      final children =
          await ref.read(parentPortalServiceProvider).getChildren();
      setState(() {
        _children = children;
        _loadingList = false;
      });
      // Auto-select first child
      if (children.isNotEmpty) {
        _selectChild(children.first.id);
      }
    } catch (e) {
      setState(() => _loadingList = false);
    }
  }

  Future<void> _selectChild(int studentId) async {
    setState(() {
      _selectedChildId = studentId;
      _loadingDetail = true;
    });
    try {
      final detail =
          await ref.read(parentPortalServiceProvider).getChildDetail(studentId);
      setState(() {
        _selectedChildDetail = detail;
        _loadingDetail = false;
      });
    } catch (e) {
      setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Hijos')),
      body: _loadingList
          ? const LoadingWidget(message: 'Cargando...')
          : _children.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.users,
                  title: 'Sin hijos vinculados',
                  description: 'Contacta a la institución para vincular a tus hijos.')
              : Column(
                  children: [
                    // Child selector tabs
                    if (_children.length > 1)
                      SizedBox(
                        height: 56,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _children.length,
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            final isSelected =
                                child.id == _selectedChildId;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(child.fullName),
                                selected: isSelected,
                                onSelected: (_) =>
                                    _selectChild(child.id),
                              ),
                            );
                          },
                        ),
                      ),

                    // Child detail
                    Expanded(
                      child: _loadingDetail
                          ? const LoadingWidget(
                              message: 'Cargando información...')
                          : _selectedChildDetail == null
                              ? const Center(
                                  child:
                                      Text('Selecciona un hijo'))
                              : RefreshIndicator(
                                  onRefresh: () => _selectChild(
                                      _selectedChildId!),
                                  child: _buildChildDetail(
                                      theme, _selectedChildDetail!),
                                ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChildDetail(ThemeData theme, ParentChildDetail child) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Student info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  child.fullName.isNotEmpty
                      ? child.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Código: ${child.studentCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    if (child.currentEnrollment != null)
                      Text(child.currentEnrollment!.courseName,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/parent/children/${child.id}'),
            icon: const Icon(LucideIcons.externalLink, size: 16),
            label: const Text('Ver detalle completo'),
          ),
        ),
        const SizedBox(height: 16),

        // Grades section
        if (child.grades != null) ...[
          _sectionHeader(theme, LucideIcons.fileText, 'Calificaciones',
              child.grades!.average != null
                  ? 'Promedio: ${child.grades!.average!.toStringAsFixed(1)}'
                  : null),
          const SizedBox(height: 8),
          if (child.grades!.recent.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sin calificaciones recientes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ...child.grades!.recent.take(5).map((g) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text(
                        g['subject_name'] as String? ??
                            g['course_name'] as String? ??
                            'Materia',
                        style:
                            const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        g['grade_type'] as String? ?? '',
                        style: theme.textTheme.bodySmall),
                    trailing: Text(
                      '${g['grade_value'] ?? '--'}/${g['max_grade'] ?? '100'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                )),
          const SizedBox(height: 20),
        ],

        // Attendance section
        if (child.attendance != null) ...[
          _sectionHeader(
              theme,
              LucideIcons.clipboardCheck,
              'Asistencia',
              '${child.attendance!.summary.percentage.toStringAsFixed(0)}%'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: child.attendance!.summary.percentage / 100,
                    minHeight: 10,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      child.attendance!.summary.percentage >= 80
                          ? AppTheme.successColor
                          : child.attendance!.summary.percentage >= 60
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _attStat('Presente',
                        child.attendance!.summary.present, AppTheme.successColor),
                    _attStat('Ausente',
                        child.attendance!.summary.absent, AppTheme.errorColor),
                    _attStat('Tardanza',
                        child.attendance!.summary.late, AppTheme.warningColor),
                    _attStat('Excusado',
                        child.attendance!.summary.excused, AppTheme.infoColor),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // Recent attendance
          ...child.attendance!.recent.take(5).map((a) {
            final status = a['status'] as String? ?? '';
            final date = a['date'] as String? ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: _statusIcon(status),
                title: Text(a['course_name'] as String? ?? 'Curso',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(AppDateUtils.formatDate(date)),
                trailing: _statusLabel(status),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _sectionHeader(
      ThemeData theme, IconData icon, String title, String? trailing) {
    return Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const Spacer(),
      if (trailing != null)
        Text(trailing,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _attStat(String label, int count, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$count',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: color)),
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
