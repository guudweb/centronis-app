import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/attendance.dart';
import '../../models/grade.dart';
import '../../models/student.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/enrollments_service.dart';
import '../../services/finance_service.dart';
import '../../services/grades_service.dart';
import '../../services/students_service.dart';
import '../../widgets/common/loading_widget.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  Student? _student;
  List<dynamic> _enrollments = [];
  GradeSummary? _gradeSummary;
  List<AttendanceReport> _attendanceReports = [];
  List<Attendance> _attendanceRecords = [];
  StudentCharges? _charges;
  bool _loading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        // [0] Student
        ref
            .read(studentsServiceProvider)
            .getById(widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] getById error: $e');
          return null;
        }),
        // [1] Enrollments
        ref
            .read(enrollmentsServiceProvider)
            .getStudentEnrollments(widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] enrollments error: $e');
          return <dynamic>[];
        }),
        // [2] Grades summary
        ref
            .read(gradesServiceProvider)
            .getStudentSummary(widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] gradeSummary error: $e');
          return null;
        }),
        // [3] Attendance report
        ref
            .read(attendanceServiceProvider)
            .getReport(studentId: widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] attendanceReport error: $e');
          return null;
        }),
        // [4] Attendance records
        ref
            .read(attendanceServiceProvider)
            .getByStudent(widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] attendanceRecords error: $e');
          return null;
        }),
        // [5] Charges
        ref
            .read(financeServiceProvider)
            .getStudentCharges(widget.studentId)
            .then<dynamic>((r) => r)
            .catchError((e) {
          // ignore: avoid_print
          print('[STUDENT_DETAIL] charges error: $e');
          return null;
        }),
      ]);

      if (!mounted) return;
      setState(() {
        final studentResponse = results[0];
        _student = studentResponse?.data;

        _enrollments =
            results[1] is List ? results[1] as List<dynamic> : [];

        final gradeResponse = results[2];
        if (gradeResponse != null) {
          try {
            _gradeSummary = gradeResponse.data as GradeSummary?;
          } catch (_) {}
        }

        final reportResponse = results[3];
        if (reportResponse != null) {
          try {
            final data = reportResponse.data;
            if (data is List<AttendanceReport>) {
              _attendanceReports = data;
            }
          } catch (_) {}
        }

        final recordsResponse = results[4];
        if (recordsResponse != null) {
          try {
            final data = recordsResponse.data;
            if (data is List<Attendance>) {
              _attendanceRecords = data;
            }
          } catch (_) {}
        }

        if (results[5] is StudentCharges) {
          _charges = results[5] as StudentCharges;
        }

        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[STUDENT_DETAIL] unexpected error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ── Helpers ──

  String? get _activeCourseName {
    for (final e in _enrollments) {
      final m = e as Map<String, dynamic>;
      final status = m['status'] as String?;
      if (status == 'active' || status == 'enrolled') {
        final course = m['course'] as Map<String, dynamic>?;
        if (course != null) return course['name'] as String?;
      }
    }
    return null;
  }

  String get _currency =>
      ref.read(authProvider).user?.institution?.currency ?? 'XAF';

  int get _guardianCount {
    int count = 0;
    if (_student?.guardian1Name != null &&
        _student!.guardian1Name!.isNotEmpty) {
      count++;
    }
    if (_student?.guardian2Name != null &&
        _student!.guardian2Name!.isNotEmpty) {
      count++;
    }
    return count;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Estudiante')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando perfil...')
          : _student == null
              ? const Center(child: Text('Estudiante no encontrado'))
              : Column(
                  children: [
                    _buildHeader(theme),
                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        const Tab(text: 'Información Personal'),
                        Tab(
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              const Text('Padres/Tutores'),
                              const SizedBox(width: 6),
                              _badgeCount(_guardianCount),
                            ])),
                        const Tab(text: 'Calificaciones'),
                        const Tab(text: 'Asistencia'),
                        const Tab(text: 'Cargos y Pagos'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPersonalInfoTab(theme),
                          _buildGuardiansTab(theme),
                          _buildGradesTab(theme),
                          _buildAttendanceTab(theme),
                          _buildChargesTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Header ──

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          child: Text(
            _getInitials(_student!.fullName),
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(_student!.fullName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _statusChip(_student!.status),
              ]),
              const SizedBox(height: 2),
              Text(_student!.studentCode,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(_student!.user?.email ?? '',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (_activeCourseName != null)
                Text(_activeCourseName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Tab 1: Personal Info ──

  Widget _buildPersonalInfoTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(theme, LucideIcons.user, 'Datos Personales'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _infoRow(theme, 'Email', _student!.user?.email ?? 'N/A'),
                _infoRow(theme, 'Teléfono', _student!.user?.phone ?? 'N/A'),
                _infoRow(theme, 'Documento',
                    '${_student!.user?.documentType ?? ''} ${_student!.user?.documentNumber ?? 'N/A'}'),
                _infoRow(
                    theme,
                    'Fecha de nacimiento',
                    _student!.user?.birthDate != null
                        ? AppDateUtils.formatDate(_student!.user!.birthDate!)
                        : 'N/A'),
                _infoRow(
                    theme, 'Género', _genderLabel(_student!.user?.gender)),
                _infoRow(
                    theme, 'Dirección', _student!.user?.address ?? 'N/A'),
                _infoRow(theme, 'Fecha de admisión',
                    AppDateUtils.formatDate(_student!.admissionDate)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
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
                _infoRow(
                    theme, 'Info médica', _student!.medicalInfo ?? 'N/A'),
              ]),
            ),
          ),
          if (_student!.notes != null && _student!.notes!.isNotEmpty) ...[
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
    );
  }

  // ── Tab 2: Guardians ──

  Widget _buildGuardiansTab(ThemeData theme) {
    final hasG1 = _student!.guardian1Name != null &&
        _student!.guardian1Name!.isNotEmpty;
    final hasG2 = _student!.guardian2Name != null &&
        _student!.guardian2Name!.isNotEmpty;

    if (!hasG1 && !hasG2) {
      return Center(
        child: Text('Sin padres o tutores registrados',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasG1) ...[
            _sectionTitle(theme, LucideIcons.shieldCheck, 'Acudiente 1'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _infoRow(theme, 'Nombre', _student!.guardian1Name!),
                  _infoRow(theme, 'Relación',
                      _student!.guardian1Relationship ?? 'N/A'),
                  _infoRow(
                      theme, 'Teléfono', _student!.guardian1Phone ?? 'N/A'),
                  _infoRow(
                      theme, 'Email', _student!.guardian1Email ?? 'N/A'),
                ]),
              ),
            ),
          ],
          if (hasG1 && hasG2) const SizedBox(height: 16),
          if (hasG2) ...[
            _sectionTitle(theme, LucideIcons.shieldCheck, 'Acudiente 2'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _infoRow(theme, 'Nombre', _student!.guardian2Name!),
                  _infoRow(theme, 'Relación',
                      _student!.guardian2Relationship ?? 'N/A'),
                  _infoRow(
                      theme, 'Teléfono', _student!.guardian2Phone ?? 'N/A'),
                  _infoRow(
                      theme, 'Email', _student!.guardian2Email ?? 'N/A'),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 4: Grades ──

  Widget _buildGradesTab(ThemeData theme) {
    if (_gradeSummary == null) {
      return Center(
        child: Text('Sin calificaciones disponibles',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Text('Promedio General (GPA)',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  _gradeSummary!.gpa.toStringAsFixed(2),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: _gpaColor(_gradeSummary!.gpa)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(theme, LucideIcons.bookOpen, 'Promedios por Curso'),
          const SizedBox(height: 8),
          if (_gradeSummary!.courses.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    Text('Sin cursos', style: theme.textTheme.bodyMedium),
              ),
            )
          else
            ..._gradeSummary!.courses.map((course) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.fileBarChart,
                          size: 18, color: AppTheme.warningColor),
                    ),
                    title: Text(course.courseName,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(course.courseCode),
                    trailing: Text(
                      course.overallAverage.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _gpaColor(course.overallAverage)),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ── Tab 5: Attendance ──

  Widget _buildAttendanceTab(ThemeData theme) {
    if (_attendanceReports.isEmpty && _attendanceRecords.isEmpty) {
      return Center(
        child: Text('Sin registros de asistencia',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_attendanceReports.isNotEmpty) ...[
            _sectionTitle(
                theme, LucideIcons.pieChart, 'Resumen de Asistencia'),
            const SizedBox(height: 8),
            ..._attendanceReports.map((report) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (report.courseName != null &&
                            report.courseName!.isNotEmpty)
                          Text(report.courseName!,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: report.attendanceRate / 100,
                                minHeight: 8,
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                    report.attendanceRate >= 80
                                        ? AppTheme.successColor
                                        : report.attendanceRate >= 60
                                            ? AppTheme.warningColor
                                            : AppTheme.errorColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                              '${report.attendanceRate.toStringAsFixed(0)}%',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _attendancePill(theme, 'Presente',
                              report.presentCount, AppTheme.successColor),
                          const SizedBox(width: 6),
                          _attendancePill(theme, 'Ausente',
                              report.absentCount, AppTheme.errorColor),
                          const SizedBox(width: 6),
                          _attendancePill(theme, 'Tarde',
                              report.lateCount, AppTheme.warningColor),
                          const SizedBox(width: 6),
                          _attendancePill(theme, 'Excusado',
                              report.excusedCount, AppTheme.infoColor),
                        ]),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (_attendanceRecords.isNotEmpty) ...[
            _sectionTitle(theme, LucideIcons.list,
                'Registros (${_attendanceRecords.length})'),
            const SizedBox(height: 8),
            ..._attendanceRecords.take(50).map((record) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    leading: _attendanceStatusIcon(record.status),
                    title: Text(
                        record.courseName ?? 'Curso #${record.courseId}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(AppDateUtils.formatDate(record.date)),
                    trailing: _attendanceStatusChip(record.status),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ── Tab 6: Charges ──

  Widget _buildChargesTab(ThemeData theme) {
    if (_charges == null) {
      return Center(
        child: Text('Sin información de cargos',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }

    final summary = _charges!.summary;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                  child: _chargeSummaryItem(theme, 'Total Cobrado',
                      summary.totalCharged, AppTheme.primaryColor),
                ),
                Expanded(
                  child: _chargeSummaryItem(theme, 'Total Pagado',
                      summary.totalPaid, AppTheme.successColor),
                ),
                Expanded(
                  child: _chargeSummaryItem(theme, 'Pendiente',
                      summary.totalPending, AppTheme.errorColor),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle(theme, LucideIcons.wallet,
              'Cargos (${_charges!.charges.length})'),
          const SizedBox(height: 8),
          if (_charges!.charges.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sin cargos registrados',
                    style: theme.textTheme.bodyMedium),
              ),
            )
          else
            ..._charges!.charges.map((charge) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(charge.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          _chargeStatusChip(charge.status),
                        ]),
                        if (charge.conceptName != null) ...[
                          const SizedBox(height: 4),
                          Text(charge.conceptName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          _chargeAmount(theme, 'Monto', charge.amountDue),
                          _chargeAmount(
                              theme, 'Pagado', charge.amountPaid),
                          _chargeAmount(theme, 'Saldo', charge.balance),
                        ]),
                        if (charge.dueDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                              'Vence: ${AppDateUtils.formatDate(charge.dueDate!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ── Shared Helpers ──

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

  Widget _badgeCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor)),
    );
  }

  Color _gpaColor(double value) {
    if (value >= 4.0) return AppTheme.successColor;
    if (value >= 3.0) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Widget _attendancePill(
      ThemeData theme, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
              maxLines: 1),
        ]),
      ),
    );
  }

  Widget _attendanceStatusIcon(String status) {
    final (icon, color) = switch (status) {
      'present' => (LucideIcons.checkCircle, AppTheme.successColor),
      'absent' => (LucideIcons.xCircle, AppTheme.errorColor),
      'late' => (LucideIcons.clock, AppTheme.warningColor),
      'excused' => (LucideIcons.info, AppTheme.infoColor),
      _ => (LucideIcons.helpCircle, Colors.grey),
    };
    return Icon(icon, color: color, size: 22);
  }

  Widget _attendanceStatusChip(String status) {
    final (label, color) = switch (status) {
      'present' => ('Presente', AppTheme.successColor),
      'absent' => ('Ausente', AppTheme.errorColor),
      'late' => ('Tarde', AppTheme.warningColor),
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
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _chargeSummaryItem(
      ThemeData theme, String label, double amount, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${amount.toStringAsFixed(0)} $_currency',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _chargeStatusChip(String status) {
    final (label, color) = switch (status) {
      'pending' => ('Pendiente', AppTheme.warningColor),
      'partial' => ('Parcial', AppTheme.infoColor),
      'paid' => ('Pagado', AppTheme.successColor),
      'overdue' => ('Vencido', AppTheme.errorColor),
      'cancelled' => ('Cancelado', Colors.grey),
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

  Widget _chargeAmount(ThemeData theme, String label, double amount) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${amount.toStringAsFixed(0)} $_currency',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: theme.textTheme.labelSmall),
      ]),
    );
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
