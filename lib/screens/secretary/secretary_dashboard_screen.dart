import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/students_service.dart';
import '../../services/courses_service.dart';

class SecretaryDashboardScreen extends ConsumerStatefulWidget {
  const SecretaryDashboardScreen({super.key});

  @override
  ConsumerState<SecretaryDashboardScreen> createState() =>
      _SecretaryDashboardScreenState();
}

class _SecretaryDashboardScreenState
    extends ConsumerState<SecretaryDashboardScreen> {
  int _totalStudents = 0;
  int _totalCourses = 0;
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
        ref
            .read(studentsServiceProvider)
            .getAll(page: 1, limit: 1)
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        ref
            .read(coursesServiceProvider)
            .getAll(page: 1, limit: 1)
            .then<dynamic>((r) => r)
            .catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        if (results[0] != null) {
          _totalStudents = results[0].pagination?.total ?? 0;
        }
        if (results[1] != null) {
          _totalCourses = results[1].pagination?.total ?? 0;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Secretaría')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hola, ${auth.user?.firstName ?? ''}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(children: [
                Expanded(
                  child: _quickCard(
                    theme,
                    'Estudiantes',
                    '$_totalStudents',
                    LucideIcons.graduationCap,
                    AppTheme.primaryColor,
                    () => context.go('/secretary/students'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickCard(
                    theme,
                    'Cursos',
                    '$_totalCourses',
                    LucideIcons.bookOpen,
                    AppTheme.accentColor,
                    () => context.go('/secretary/courses'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _quickCard(
                    theme,
                    'Horarios',
                    '',
                    LucideIcons.calendar,
                    AppTheme.warningColor,
                    () => context.go('/secretary/schedule'),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickCard(ThemeData theme, String title, String value,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              if (value.isNotEmpty)
                Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color)),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
