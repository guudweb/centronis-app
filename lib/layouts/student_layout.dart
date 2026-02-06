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
      icon: Icon(LucideIcons.calendarDays),
      label: 'Calendario',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.user),
      label: 'Perfil',
    ),
  ];

  static const _routes = [
    '/student/dashboard',
    '/student/courses',
    '/student/grades',
    '/student/events',
    '/student/profile',
  ];

  // All items for the drawer (wide layout)
  static const _allDrawerItems = [
    DrawerItem(icon: LucideIcons.layoutDashboard, label: 'Inicio'),
    DrawerItem(icon: LucideIcons.bookOpen, label: 'Cursos'),
    DrawerItem(icon: LucideIcons.fileText, label: 'Notas'),
    DrawerItem(icon: LucideIcons.clipboardList, label: 'Tareas'),
    DrawerItem(icon: LucideIcons.calendar, label: 'Horario'),
    DrawerItem(icon: LucideIcons.megaphone, label: 'Anuncios'),
    DrawerItem(icon: LucideIcons.calendarDays, label: 'Calendario'),
    DrawerItem(icon: LucideIcons.graduationCap, label: 'Boletín'),
    DrawerItem(icon: LucideIcons.user, label: 'Perfil'),
  ];

  static const _allRoutes = [
    '/student/dashboard',
    '/student/courses',
    '/student/grades',
    '/student/assignments',
    '/student/schedule',
    '/student/announcements',
    '/student/events',
    '/student/grades/report-card',
    '/student/profile',
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  void _onDrawerItemTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_allRoutes[index]);
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
        selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
