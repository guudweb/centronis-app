import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/students_service.dart';
import '../../services/teachers_service.dart';
import '../../services/courses_service.dart';
import '../../services/announcements_service.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../core/utils/date_utils.dart';

class _DashboardStats {
  final int totalStudents;
  final int totalTeachers;
  final int totalCourses;
  final int totalAnnouncements;

  const _DashboardStats({
    this.totalStudents = 0,
    this.totalTeachers = 0,
    this.totalCourses = 0,
    this.totalAnnouncements = 0,
  });
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  _DashboardStats _stats = const _DashboardStats();
  List<dynamic> _recentAnnouncements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);

    try {
      // Fetch all stats in parallel
      final results = await Future.wait([
        ref.read(studentsServiceProvider).getAll(page: 1, limit: 1),
        ref.read(teachersServiceProvider).getAll(page: 1, limit: 1),
        ref.read(coursesServiceProvider).getAll(page: 1, limit: 1),
        ref.read(announcementsServiceProvider).getAll(page: 1, limit: 5),
      ]);

      final studentsResponse = results[0];
      final teachersResponse = results[1];
      final coursesResponse = results[2];
      final announcementsResponse = results[3];

      setState(() {
        _stats = _DashboardStats(
          totalStudents: (studentsResponse as dynamic).pagination.total,
          totalTeachers: (teachersResponse as dynamic).pagination.total,
          totalCourses: (coursesResponse as dynamic).pagination.total,
          totalAnnouncements:
              (announcementsResponse as dynamic).pagination.total,
        );
        _recentAnnouncements = (announcementsResponse as dynamic).data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final tenant = ref.watch(tenantProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.tenantName),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
            tooltip: 'Notificaciones',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Cargando panel...')
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Greeting
                  Text(
                    'Bienvenido, ${auth.user?.firstName ?? ''}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panel de administración',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats grid - real data
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.4,
                        children: [
                          StatCard(
                            title: 'Estudiantes',
                            value: '${_stats.totalStudents}',
                            icon: LucideIcons.graduationCap,
                            color: AppTheme.primaryColor,
                          ),
                          StatCard(
                            title: 'Profesores',
                            value: '${_stats.totalTeachers}',
                            icon: LucideIcons.users,
                            color: AppTheme.secondaryColor,
                          ),
                          StatCard(
                            title: 'Cursos',
                            value: '${_stats.totalCourses}',
                            icon: LucideIcons.bookOpen,
                            color: AppTheme.accentColor,
                          ),
                          StatCard(
                            title: 'Anuncios',
                            value: '${_stats.totalAnnouncements}',
                            icon: LucideIcons.megaphone,
                            color: AppTheme.warningColor,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Recent announcements
                  Text(
                    'Anuncios recientes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recentAnnouncements.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No hay anuncios recientes',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_recentAnnouncements).map((announcement) {
                      final a = announcement;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.megaphone,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            AppDateUtils.relativeTime(a.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: const Icon(
                              LucideIcons.chevronRight, size: 18),
                          onTap: () {},
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
