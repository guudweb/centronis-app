import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../services/students_service.dart';
import '../../models/student.dart';
import '../../models/api_response.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentsManagementScreen extends ConsumerStatefulWidget {
  const StudentsManagementScreen({super.key});

  @override
  ConsumerState<StudentsManagementScreen> createState() =>
      _StudentsManagementScreenState();
}

class _StudentsManagementScreenState
    extends ConsumerState<StudentsManagementScreen> {
  final _searchController = TextEditingController();
  List<Student> _students = [];
  Pagination? _pagination;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref.read(studentsServiceProvider).getAll(
            page: page,
            limit: 20,
            search: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
          );
      setState(() {
        _students = response.data;
        _pagination = response.pagination;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Error al cargar estudiantes';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () {
              // TODO: Navigate to create student
            },
            tooltip: 'Nuevo estudiante',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiantes...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.search),
                  onPressed: () => _loadStudents(),
                ),
              ),
              onSubmitted: (_) => _loadStudents(),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Cargando estudiantes...')
                : _error != null
                    ? EmptyState(
                        icon: LucideIcons.alertCircle,
                        title: 'Error',
                        description: _error,
                        actionLabel: 'Reintentar',
                        onAction: _loadStudents,
                      )
                    : _students.isEmpty
                        ? const EmptyState(
                            icon: LucideIcons.graduationCap,
                            title: 'Sin estudiantes',
                            description:
                                'Agrega estudiantes para comenzar.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStudents,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _students.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      student.fullName.isNotEmpty
                                          ? student.fullName[0]
                                              .toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    student.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${student.studentCode} - ${student.user?.email ?? ''}',
                                  ),
                                  trailing: _buildStatusChip(
                                      student.status, theme),
                                  onTap: () => context.push(
                                      '/admin/students/${student.id}'),
                                );
                              },
                            ),
                          ),
          ),

          // Pagination
          if (_pagination != null && _pagination!.totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: _pagination!.hasPrev
                        ? () =>
                            _loadStudents(page: _pagination!.page - 1)
                        : null,
                  ),
                  Text(
                    'Página ${_pagination!.page} de ${_pagination!.totalPages}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight),
                    onPressed: _pagination!.hasNext
                        ? () =>
                            _loadStudents(page: _pagination!.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    final (label, color) = switch (status) {
      'active' => ('Activo', Colors.green),
      'inactive' => ('Inactivo', Colors.grey),
      'graduated' => ('Graduado', Colors.blue),
      'transferred' => ('Transferido', Colors.orange),
      _ => (status, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
