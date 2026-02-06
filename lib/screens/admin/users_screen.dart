import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';

import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../models/api_response.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  List<User> _users = [];
  Pagination? _pagination;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref.read(usersServiceProvider).getAll(
            page: page,
            limit: 20,
            search: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
          );
      if (!mounted) return;
      setState(() {
        _users = response.data;
        _pagination = response.pagination;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data?['message'] ?? 'Error al cargar usuarios';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar usuarios';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: () {
              // TODO: Navigate to create user
            },
            tooltip: 'Nuevo usuario',
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
                hintText: 'Buscar usuarios...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.search),
                  onPressed: () => _loadUsers(),
                ),
              ),
              onSubmitted: (_) => _loadUsers(),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Cargando usuarios...')
                : _error != null
                    ? EmptyState(
                        icon: LucideIcons.alertCircle,
                        title: 'Error',
                        description: _error,
                        actionLabel: 'Reintentar',
                        onAction: _loadUsers,
                      )
                    : _users.isEmpty
                        ? const EmptyState(
                            icon: LucideIcons.users,
                            title: 'Sin usuarios',
                            description:
                                'Los usuarios de la institución aparecerán aquí.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _users.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(user.email),
                                  trailing: _buildRoleChip(user, theme),
                                  onTap: () {},
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
                        ? () => _loadUsers(page: _pagination!.page - 1)
                        : null,
                  ),
                  Text(
                    'Página ${_pagination!.page} de ${_pagination!.totalPages}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight),
                    onPressed: _pagination!.hasNext
                        ? () => _loadUsers(page: _pagination!.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(User user, ThemeData theme) {
    final roleName = user.roleName;
    final (label, color) = switch (roleName.toLowerCase()) {
      'admin' || 'super_admin' => ('Admin', Colors.purple),
      'director' => ('Director', Colors.indigo),
      'teacher' || 'profesor' => ('Profesor', Colors.blue),
      'student' || 'estudiante' => ('Estudiante', Colors.green),
      'secretary' || 'secretaria' => ('Secretaria', Colors.orange),
      'parent' || 'padre' => ('Padre', Colors.teal),
      _ => (roleName.isNotEmpty ? roleName : 'Sin rol', Colors.grey),
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
