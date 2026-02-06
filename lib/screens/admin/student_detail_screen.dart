import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/students_service.dart';
import '../../services/enrollments_service.dart';
import '../../models/student.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  Student? _student;
  List<dynamic> _enrollments = [];
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
        ref.read(studentsServiceProvider).getById(widget.studentId),
        ref.read(enrollmentsServiceProvider).getStudentEnrollments(widget.studentId).catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _student = (results[0] as dynamic).data;
        _enrollments = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Estudiante')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando perfil...')
          : _student == null
              ? const Center(child: Text('Estudiante no encontrado'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  _student!.fullName.isNotEmpty
                                      ? _student!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(_student!.fullName,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Código: ${_student!.studentCode}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 8),
                              _statusChip(_student!.status),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(children: [
                        Expanded(
                            child: _miniStat(
                                theme,
                                'Matrículas',
                                '${_enrollments.length}',
                                AppTheme.primaryColor)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _miniStat(theme, 'Estado',
                                _statusLabel(_student!.status), AppTheme.successColor)),
                      ]),
                      const SizedBox(height: 16),

                      // Personal info
                      _sectionTitle(theme, LucideIcons.user, 'Información Personal'),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _infoRow(theme, 'Email',
                                _student!.user?.email ?? 'N/A'),
                            _infoRow(theme, 'Teléfono',
                                _student!.user?.phone ?? 'N/A'),
                            _infoRow(theme, 'Documento',
                                '${_student!.user?.documentType ?? ''} ${_student!.user?.documentNumber ?? 'N/A'}'),
                            _infoRow(theme, 'Fecha de nacimiento',
                                _student!.user?.birthDate != null
                                    ? AppDateUtils.formatDate(
                                        _student!.user!.birthDate!)
                                    : 'N/A'),
                            _infoRow(theme, 'Género',
                                _genderLabel(_student!.user?.gender)),
                            _infoRow(theme, 'Dirección',
                                _student!.user?.address ?? 'N/A'),
                            _infoRow(theme, 'Fecha de admisión',
                                AppDateUtils.formatDate(
                                    _student!.admissionDate)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Guardian 1
                      if (_student!.guardian1Name != null) ...[
                        _sectionTitle(
                            theme, LucideIcons.shieldCheck, 'Acudiente 1'),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _infoRow(theme, 'Nombre',
                                  _student!.guardian1Name!),
                              _infoRow(theme, 'Relación',
                                  _student!.guardian1Relationship ?? 'N/A'),
                              _infoRow(theme, 'Teléfono',
                                  _student!.guardian1Phone ?? 'N/A'),
                              _infoRow(theme, 'Email',
                                  _student!.guardian1Email ?? 'N/A'),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Guardian 2
                      if (_student!.guardian2Name != null) ...[
                        _sectionTitle(
                            theme, LucideIcons.shieldCheck, 'Acudiente 2'),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _infoRow(theme, 'Nombre',
                                  _student!.guardian2Name!),
                              _infoRow(theme, 'Relación',
                                  _student!.guardian2Relationship ?? 'N/A'),
                              _infoRow(theme, 'Teléfono',
                                  _student!.guardian2Phone ?? 'N/A'),
                              _infoRow(theme, 'Email',
                                  _student!.guardian2Email ?? 'N/A'),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Emergency & Medical
                      _sectionTitle(theme, LucideIcons.heart, 'Emergencia y Salud'),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _infoRow(theme, 'Contacto de emergencia',
                                _student!.emergencyContact ?? 'N/A'),
                            _infoRow(theme, 'Teléfono de emergencia',
                                _student!.emergencyPhone ?? 'N/A'),
                            _infoRow(theme, 'Info médica',
                                _student!.medicalInfo ?? 'N/A'),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Enrollments
                      _sectionTitle(theme, LucideIcons.bookOpen,
                          'Matrículas (${_enrollments.length})'),
                      const SizedBox(height: 8),
                      if (_enrollments.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Sin matrículas registradas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                          ),
                        )
                      else
                        ..._enrollments.map((e) {
                          final enrollment = e as Map<String, dynamic>;
                          final course =
                              enrollment['course'] as Map<String, dynamic>?;
                          final period = enrollment['academic_period']
                              as Map<String, dynamic>?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
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
                                  course?['name'] as String? ?? 'Curso',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  period?['name'] as String? ?? ''),
                              trailing: _statusChip(
                                  enrollment['status'] as String? ??
                                      'active'),
                            ),
                          );
                        }),

                      // Notes
                      if (_student!.notes != null &&
                          _student!.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionTitle(theme, LucideIcons.fileText, 'Notas'),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_student!.notes!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'active' || 'enrolled' => ('Activo', AppTheme.successColor),
      'inactive' => ('Inactivo', Colors.grey),
      'withdrawn' => ('Retirado', AppTheme.errorColor),
      'completed' => ('Completado', AppTheme.infoColor),
      'transferred' => ('Transferido', AppTheme.warningColor),
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
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'active' => 'Activo',
      'inactive' => 'Inactivo',
      'withdrawn' => 'Retirado',
      _ => status,
    };
  }

  String _genderLabel(String? gender) {
    return switch (gender) {
      'male' || 'M' => 'Masculino',
      'female' || 'F' => 'Femenino',
      'other' => 'Otro',
      null => 'N/A',
      _ => gender,
    };
  }
}
