import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/parent_portal_service.dart';
import '../../widgets/common/loading_widget.dart';

class ParentChildDetailScreen extends ConsumerStatefulWidget {
  final int studentId;
  const ParentChildDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentChildDetailScreen> createState() =>
      _ParentChildDetailScreenState();
}

class _ParentChildDetailScreenState
    extends ConsumerState<ParentChildDetailScreen> {
  ParentChildDetail? _child;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    setState(() => _loading = true);
    try {
      final detail = await ref
          .read(parentPortalServiceProvider)
          .getChildDetail(widget.studentId);
      setState(() {
        _child = detail;
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
      appBar: AppBar(title: Text(_child?.fullName ?? 'Detalle del Hijo')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando...')
          : _child == null
              ? const Center(child: Text('No se encontró información'))
              : RefreshIndicator(
                  onRefresh: _loadChild,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                _child!.fullName.isNotEmpty
                                    ? _child!.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_child!.fullName,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700)),
                                  Text('Código: ${_child!.studentCode}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant)),
                                  if (_child!.relationship != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _relationshipLabel(
                                            _child!.relationship!),
                                        style: const TextStyle(
                                            color: AppTheme.accentColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats cards
                      Row(children: [
                        Expanded(
                            child: _statCard(
                          theme,
                          'Promedio',
                          _child!.grades?.average?.toStringAsFixed(1) ??
                              '--',
                          AppTheme.primaryColor,
                        )),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _statCard(
                          theme,
                          'Asistencia',
                          _child!.attendance != null
                              ? '${_child!.attendance!.summary.percentage.toStringAsFixed(0)}%'
                              : '--',
                          AppTheme.successColor,
                        )),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _statCard(
                          theme,
                          'Estado',
                          _child!.status == 'active'
                              ? 'Activo'
                              : _child!.status,
                          AppTheme.infoColor,
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // Current enrollment
                      if (_child!.currentEnrollment != null)
                        Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(LucideIcons.bookOpen,
                                  size: 18, color: AppTheme.accentColor),
                            ),
                            title: Text(
                                _child!.currentEnrollment!.courseName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: const Text('Matrícula actual'),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Quick access navigation
                      Text('Acceso rápido',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _navCard(
                        theme,
                        LucideIcons.fileText,
                        'Calificaciones',
                        'Ver todas las calificaciones',
                        AppTheme.primaryColor,
                        () => context.push(
                            '/parent/children/${widget.studentId}/grades'),
                      ),
                      _navCard(
                        theme,
                        LucideIcons.clipboardCheck,
                        'Asistencia',
                        'Historial de asistencia',
                        AppTheme.successColor,
                        () => context.push(
                            '/parent/children/${widget.studentId}/attendance'),
                      ),
                      _navCard(
                        theme,
                        LucideIcons.clipboardList,
                        'Tareas',
                        'Tareas y entregas',
                        AppTheme.warningColor,
                        () => context.push(
                            '/parent/children/${widget.studentId}/assignments'),
                      ),
                      _navCard(
                        theme,
                        LucideIcons.graduationCap,
                        'Boletín',
                        'Boletín de calificaciones',
                        AppTheme.accentColor,
                        () => context.push(
                            '/parent/children/${widget.studentId}/report-card'),
                      ),
                      _navCard(
                        theme,
                        LucideIcons.receipt,
                        'Cargos y Pagos',
                        'Estado de cuenta y pagos',
                        AppTheme.errorColor,
                        () => context.push(
                            '/parent/children/${widget.studentId}/charges'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(
      ThemeData theme, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
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

  Widget _navCard(ThemeData theme, IconData icon, String title,
      String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(LucideIcons.chevronRight, size: 18),
        onTap: onTap,
      ),
    );
  }

  String _relationshipLabel(String relationship) {
    return switch (relationship.toLowerCase()) {
      'father' => 'Padre',
      'mother' => 'Madre',
      'guardian' => 'Tutor',
      'grandparent' => 'Abuelo/a',
      'sibling' => 'Hermano/a',
      _ => relationship,
    };
  }
}
