import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../widgets/common/app_drawer.dart';

class ParentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const ParentLayout({super.key, required this.child});

  @override
  ConsumerState<ParentLayout> createState() => _ParentLayoutState();
}

class _ParentLayoutState extends ConsumerState<ParentLayout> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(LucideIcons.layoutDashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.users),
      label: 'Hijos',
    ),
    NavigationDestination(
      icon: Icon(LucideIcons.calendarDays),
      label: 'Calendario',
    ),
  ];

  static const _routes = [
    '/parent/dashboard',
    '/parent/children',
    '/parent/events',
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
              userRole: 'Padre/Madre',
              institutionName: tenant.tenantName,
              logoUrl: tenant.tenantLogo,
              selectedIndex: _selectedIndex,
              items: const [
                DrawerItem(
                    icon: LucideIcons.layoutDashboard, label: 'Inicio'),
                DrawerItem(icon: LucideIcons.users, label: 'Hijos'),
                DrawerItem(
                    icon: LucideIcons.calendarDays, label: 'Calendario'),
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
