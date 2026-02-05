import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/courses_service.dart';
import '../../services/enrollments_service.dart';
import '../../models/course.dart';
import '../../widgets/common/loading_widget.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  Course? _course;
  List<EnrolledStudent> _students = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        ref.read(coursesServiceProvider).getById(widget.courseId),
        ref.read(enrollmentsServiceProvider).getCourseEnrollments(widget.courseId),
      ]);
      setState(() {
        _course = (results[0] as dynamic).data;
        _students = results[1] as List<EnrolledStudent>;
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
      appBar: AppBar(
        title: Text(_course?.name ?? 'Detalle del Curso'),
        bottom: _loading
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Información'),
                  Tab(text: 'Estudiantes'),
                ],
              ),
      ),
      body: _loading
          ? const LoadingWidget(message: 'Cargando curso...')
          : _course == null
              ? const Center(child: Text('Curso no encontrado'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(theme),
                    _buildStudentsTab(theme),
                  ],
                ),
    );
  }

  Widget _buildInfoTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Course header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(LucideIcons.bookOpen,
                        size: 32, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(_course!.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Código: ${_course!.code}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Row(children: [
            Expanded(
                child: _statCard(
                    theme,
                    'Matriculados',
                    '${_students.length}',
                    LucideIcons.users,
                    AppTheme.primaryColor)),
            const SizedBox(width: 8),
            Expanded(
                child: _statCard(
                    theme,
                    'Capacidad',
                    '${_course!.capacity ?? '--'}',
                    LucideIcons.userPlus,
                    AppTheme.accentColor)),
          ]),
          const SizedBox(height: 16),

          // Course details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _detailRow(theme, 'Nivel', _course!.level ?? 'N/A'),
                _detailRow(theme, 'Sección', _course!.section ?? 'N/A'),
                _detailRow(
                    theme,
                    'Periodo Académico',
                    _course!.academicPeriod?.name ?? 'N/A'),
                _detailRow(
                    theme,
                    'Escala de calificación',
                    _course!.gradeScale?.name ?? 'N/A'),
                _detailRow(
                    theme, 'Estado', _course!.active ? 'Activo' : 'Inactivo'),
                if (_course!.capacity != null)
                  Column(children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _course!.capacity! > 0
                                  ? _students.length / _course!.capacity!
                                  : 0,
                              minHeight: 8,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                _students.length >= (_course!.capacity ?? 0)
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_students.length}/${_course!.capacity}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab(ThemeData theme) {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No hay estudiantes matriculados',
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                child: Text(
                  student.fullName.isNotEmpty
                      ? student.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(student.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(student.studentCode),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () => context.push(
                  '/admin/students/${student.studentId}'),
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(ThemeData theme, String label, String value,
      IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
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
}
