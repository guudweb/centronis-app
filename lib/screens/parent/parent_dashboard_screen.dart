import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/announcement.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../services/announcements_service.dart';
import '../../services/events_service.dart';
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
  List<Announcement> _announcements = [];
  List<CalendarEvent> _events = [];
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
            .read(parentPortalServiceProvider)
            .getChildren()
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        ref
            .read(announcementsServiceProvider)
            .getAll(page: 1, limit: 5)
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        ref
            .read(eventsServiceProvider)
            .getAll(
              startDate: AppDateUtils.toIso(DateTime.now()),
              endDate: AppDateUtils.toIso(
                  DateTime.now().add(const Duration(days: 30))),
              limit: 5,
            )
            .then<dynamic>((r) => r)
            .catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        if (results[0] != null) {
          _children = results[0] as List<ParentChild>;
        }
        if (results[1] != null) {
          _announcements = (results[1] as dynamic).data ?? [];
        }
        if (results[2] != null) {
          _events = results[2] as List<CalendarEvent>;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Portal de Padres')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando...')
          : RefreshIndicator(
              onRefresh: _loadData,
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
                  _sectionHeader(theme, 'Mis hijos', LucideIcons.users),
                  const SizedBox(height: 8),
                  if (_children.isEmpty)
                    _emptyCard(theme,
                        'No tienes hijos vinculados. Contacta a la institución.')
                  else
                    ..._children.map((child) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                context.push('/parent/children/${child.id}'),
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
                                            style: theme.textTheme.bodySmall
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
                  const SizedBox(height: 24),

                  // Announcements
                  _sectionHeader(
                      theme, 'Anuncios recientes', LucideIcons.megaphone),
                  const SizedBox(height: 8),
                  if (_announcements.isEmpty)
                    _emptyCard(theme, 'No hay anuncios')
                  else
                    ..._announcements.map((a) => Card(
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
                              child: const Icon(LucideIcons.megaphone,
                                  size: 18, color: AppTheme.primaryColor),
                            ),
                            title: Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                AppDateUtils.relativeTime(a.createdAt),
                                style: theme.textTheme.bodySmall),
                          ),
                        )),
                  const SizedBox(height: 24),

                  // Upcoming events
                  _sectionHeader(
                      theme, 'Próximos eventos', LucideIcons.calendarDays),
                  const SizedBox(height: 8),
                  if (_events.isEmpty)
                    _emptyCard(theme, 'No hay eventos próximos')
                  else
                    ..._events.take(3).map((e) => _eventCard(theme, e)),
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

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _emptyCard(ThemeData theme, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Widget _eventCard(ThemeData theme, CalendarEvent event) {
    final color = switch (event.eventType) {
      'holiday' => Colors.red,
      'exam' => Colors.amber.shade700,
      'meeting' => Colors.blue,
      'activity' => Colors.green,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.calendarDays, size: 18, color: color),
        ),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: event.startDate.isNotEmpty
            ? Text(AppDateUtils.formatDate(event.startDate),
                style: theme.textTheme.bodySmall)
            : null,
      ),
    );
  }
}
