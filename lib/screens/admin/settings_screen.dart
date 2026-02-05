import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final tenant = ref.watch(tenantProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Institution info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.building2, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Institución',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _SettingsRow(
                    label: 'Nombre',
                    value: tenant.tenantName,
                  ),
                  _SettingsRow(
                    label: 'Slug',
                    value: tenant.tenantSlug ?? '--',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Profile
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.user, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Perfil',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _SettingsRow(
                    label: 'Nombre',
                    value: auth.user?.fullName ?? '--',
                  ),
                  _SettingsRow(
                    label: 'Email',
                    value: auth.user?.email ?? '--',
                  ),
                  _SettingsRow(
                    label: 'Rol',
                    value: auth.user?.roleName ?? '--',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Account actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.keyRound),
                  title: const Text('Cambiar contraseña'),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(LucideIcons.logOut,
                      color: Colors.redAccent),
                  title: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
