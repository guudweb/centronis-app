import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../widgets/common/app_drawer.dart';

class AdminLayout extends ConsumerStatefulWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.layoutDashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.users),
      label: 'Usuarios',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.graduationCap),
      label: 'Estudiantes',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.bookOpen),
      label: 'Cursos',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.settings),
      label: 'Ajustes',
    ),
  ];

  static const _routes = [
    '/admin/dashboard',
    '/admin/users',
    '/admin/students',
    '/admin/courses',
    '/admin/settings',
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
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
              userRole: auth.userRole,
              institutionName: tenant.tenantName,
              logoUrl: tenant.tenantLogo,
              selectedIndex: _selectedIndex,
              items: const [
                DrawerItem(icon: LucideIcons.layoutDashboard, label: 'Inicio'),
                DrawerItem(icon: LucideIcons.users, label: 'Usuarios'),
                DrawerItem(
                    icon: LucideIcons.graduationCap, label: 'Estudiantes'),
                DrawerItem(icon: LucideIcons.bookOpen, label: 'Cursos'),
                DrawerItem(icon: LucideIcons.settings, label: 'Ajustes'),
              ],
              onItemTap: _onDestinationSelected,
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
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
