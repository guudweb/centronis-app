import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/parent_portal_service.dart';
import '../../widgets/common/loading_widget.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState
    extends ConsumerState<ParentDashboardScreen> {
  List<ParentChild> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    try {
      final children =
          await ref.read(parentPortalServiceProvider).getChildren();
      setState(() {
        _children = children;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Padres'),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Cargando...')
          : RefreshIndicator(
              onRefresh: _loadChildren,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Bienvenido, ${auth.user?.firstName ?? ''}',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                      '${_children.length} hijo${_children.length == 1 ? '' : 's'} vinculado${_children.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),

                  // Children cards
                  if (_children.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(LucideIcons.users,
                              size: 40,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                              'No tienes hijos vinculados. Contacta a la institución.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center),
                        ]),
                      ),
                    )
                  else
                    ..._children.map((child) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/parent/children/${child.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      child.fullName.isNotEmpty
                                          ? child.fullName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(child.fullName,
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(
                                            '${child.studentCode} - ${_relationshipLabel(child.relationship)}',
                                            style: theme
                                                .textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme.colorScheme
                                                        .onSurfaceVariant)),
                                        if (child.currentEnrollment !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              child.currentEnrollment!
                                                  .courseName,
                                              style: const TextStyle(
                                                  color:
                                                      AppTheme.accentColor,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.chevronRight,
                                      size: 20),
                                ],
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  String _relationshipLabel(String relationship) {
    return switch (relationship.toLowerCase()) {
      'father' => 'Padre',
      'mother' => 'Madre',
      'guardian' => 'Tutor',
      'grandparent' => 'Abuelo/a',
      'sibling' => 'Hermano/a',
      _ => relationship,
    };
  }
}
