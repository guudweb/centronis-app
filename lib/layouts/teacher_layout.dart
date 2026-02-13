import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../widgets/common/app_drawer.dart';

class TeacherLayout extends ConsumerStatefulWidget {
  final Widget child;

  const TeacherLayout({super.key, required this.child});

  @override
  ConsumerState<TeacherLayout> createState() => _TeacherLayoutState();
}

class _TeacherLayoutState extends ConsumerState<TeacherLayout> {
  int _selectedIndex = 0;

  // Bottom navigation: 4 main tabs + "Más"
  static const _destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.layoutDashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.clipboardCheck),
      label: 'Asistencia',
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

  // Routes for the first 4 bottom nav items
  static const _bottomRoutes = [
    '/teacher/dashboard',
    '/teacher/attendance',
    '/teacher/grades',
    '/teacher/assignments',
  ];

  // Items shown in the "Más" bottom sheet
  static const _moreItems = [
    (icon: LucideIcons.bookOpen, label: 'Cursos', route: '/teacher/courses'),
    (icon: LucideIcons.megaphone, label: 'Anuncios', route: '/teacher/announcements'),
    (icon: LucideIcons.calendarDays, label: 'Eventos', route: '/teacher/events'),
    (icon: LucideIcons.user, label: 'Perfil', route: '/teacher/profile'),
  ];

  // All items for the drawer (wide layout)
  static const _allDrawerItems = [
    DrawerItem(icon: LucideIcons.layoutDashboard, label: 'Inicio'),
    DrawerItem(icon: LucideIcons.bookOpen, label: 'Cursos'),
    DrawerItem(icon: LucideIcons.clipboardCheck, label: 'Asistencia'),
    DrawerItem(icon: LucideIcons.fileText, label: 'Notas'),
    DrawerItem(icon: LucideIcons.clipboardList, label: 'Tareas'),
    DrawerItem(icon: LucideIcons.megaphone, label: 'Anuncios'),
    DrawerItem(icon: LucideIcons.calendarDays, label: 'Eventos'),
    DrawerItem(icon: LucideIcons.user, label: 'Perfil'),
  ];

  static const _allRoutes = [
    '/teacher/dashboard',
    '/teacher/courses',
    '/teacher/attendance',
    '/teacher/grades',
    '/teacher/assignments',
    '/teacher/announcements',
    '/teacher/events',
    '/teacher/profile',
  ];

  void _onDestinationSelected(int index) {
    if (index == 4) {
      _showMoreMenu();
      return;
    }
    setState(() => _selectedIndex = index);
    context.go(_bottomRoutes[index]);
  }

  void _onDrawerItemTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_allRoutes[index]);
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Más opciones',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_moreItems.length, (i) {
                  final item = _moreItems[i];
                  return ListTile(
                    leading: Icon(item.icon, size: 22),
                    title: Text(item.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      final routeIndex = _allRoutes.indexOf(item.route);
                      if (routeIndex >= 0) {
                        setState(() => _selectedIndex = routeIndex);
                      }
                      context.go(item.route);
                    },
                  );
                }),
              ],
            ),
          ),
        );
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
              userRole: 'Profesor',
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

    final bottomIndex = _selectedIndex < 4 ? _selectedIndex : 4;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
