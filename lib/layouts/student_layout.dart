import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../widgets/common/app_drawer.dart';

class StudentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const StudentLayout({super.key, required this.child});

  @override
  ConsumerState<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends ConsumerState<StudentLayout> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.layoutDashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.bookOpen),
      label: 'Cursos',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.fileText),
      label: 'Notas',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.clipboardList),
      label: 'Tareas',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.menu),
      label: 'Más',
    ),
  ];

  static const _routes = [
    '/student/dashboard',
    '/student/courses',
    '/student/grades',
    '/student/assignments',
    null, // "Más" opens a bottom sheet
  ];

  // All items for the drawer (wide layout)
  static const _allDrawerItems = [
    DrawerItem(icon: LucideIcons.layoutDashboard, label: 'Inicio'),
    DrawerItem(icon: LucideIcons.bookOpen, label: 'Cursos'),
    DrawerItem(icon: LucideIcons.fileText, label: 'Notas'),
    DrawerItem(icon: LucideIcons.clipboardList, label: 'Tareas'),
    DrawerItem(icon: LucideIcons.calendar, label: 'Horario'),
    DrawerItem(icon: LucideIcons.clipboardCheck, label: 'Asistencia'),
    DrawerItem(icon: LucideIcons.megaphone, label: 'Anuncios'),
    DrawerItem(icon: LucideIcons.calendarDays, label: 'Calendario'),
    DrawerItem(icon: LucideIcons.graduationCap, label: 'Boletín'),
  ];

  static const _allRoutes = [
    '/student/dashboard',
    '/student/courses',
    '/student/grades',
    '/student/assignments',
    '/student/schedule',
    '/student/attendance',
    '/student/announcements',
    '/student/events',
    '/student/grades/report-card',
  ];

  void _onDestinationSelected(int index) {
    if (index == 4) {
      _showMoreSheet();
      return;
    }
    setState(() => _selectedIndex = index);
    context.go(_routes[index]!);
  }

  void _onDrawerItemTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_allRoutes[index]);
  }

  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _moreItem(ctx, LucideIcons.calendar, 'Horario',
                  '/student/schedule'),
              _moreItem(ctx, LucideIcons.clipboardCheck, 'Asistencia',
                  '/student/attendance'),
              _moreItem(ctx, LucideIcons.megaphone, 'Anuncios',
                  '/student/announcements'),
              _moreItem(ctx, LucideIcons.calendarDays, 'Calendario',
                  '/student/events'),
              _moreItem(ctx, LucideIcons.graduationCap, 'Boletín',
                  '/student/grades/report-card'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _moreItem(
      BuildContext ctx, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: () {
        Navigator.pop(ctx);
        context.go(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final tenant = ref.watch(tenantProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            AppDrawer(
              userName: auth.user?.fullName ?? '',
              userRole: 'Estudiante',
              institutionName: tenant.tenantName,
              logoUrl: tenant.tenantLogo,
              selectedIndex: _selectedIndex,
              items: _allDrawerItems,
              onItemTap: _onDrawerItemTap,
              onLogout: () => ref.read(authProvider.notifier).logout(),
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 4 ? _selectedIndex : 0,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
