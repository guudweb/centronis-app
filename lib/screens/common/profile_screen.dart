import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final tenant = ref.watch(tenantProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (auth.user?.fullName ?? '?')[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.user?.fullName ?? '',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(auth.user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auth.user?.roleName ?? auth.userRole,
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Institution info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.building2, size: 18),
                    const SizedBox(width: 8),
                    Text('Institución',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const Divider(height: 20),
                  _infoRow(theme, 'Nombre', tenant.tenantName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Personal info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.user, size: 18),
                    const SizedBox(width: 8),
                    Text('Información personal',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  const Divider(height: 20),
                  _infoRow(theme, 'Nombre', auth.user?.fullName ?? 'N/A'),
                  _infoRow(theme, 'Email', auth.user?.email ?? 'N/A'),
                  if (auth.user?.phone != null)
                    _infoRow(theme, 'Teléfono', auth.user!.phone!),
                  if (auth.user?.documentNumber != null)
                    _infoRow(theme, 'Documento',
                        '${auth.user?.documentType ?? ''} ${auth.user!.documentNumber!}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          Card(
            child: ListTile(
              leading:
                  const Icon(LucideIcons.logOut, color: Colors.redAccent),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
