import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/announcements_service.dart';
import '../../models/announcement.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentAnnouncementsScreen extends ConsumerStatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  ConsumerState<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends ConsumerState<StudentAnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(announcementsServiceProvider)
          .getAll(page: 1, limit: 30);
      setState(() {
        _announcements = result.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Anuncios')),
      body: _loading
          ? const LoadingWidget(message: 'Cargando anuncios...')
          : _announcements.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.megaphone,
                  title: 'Sin anuncios',
                  description: 'No hay anuncios para mostrar.')
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) =>
                        _buildCard(theme, _announcements[index]),
                  ),
                ),
    );
  }

  Widget _buildCard(ThemeData theme, Announcement announcement) {
    final priorityColor = _priorityColor(announcement.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority bar
          Container(height: 4, color: priorityColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    announcement.priority == 'high' ||
                            announcement.priority == 'urgent'
                        ? LucideIcons.alertTriangle
                        : LucideIcons.megaphone,
                    size: 18,
                    color: priorityColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(announcement.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_priorityLabel(announcement.priority),
                        style: TextStyle(
                            color: priorityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(LucideIcons.clock,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(AppDateUtils.relativeTime(announcement.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (announcement.author != null) ...[
                    const SizedBox(width: 12),
                    Icon(LucideIcons.user,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(announcement.author!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ]),
                const SizedBox(height: 10),
                Text(announcement.content,
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    return switch (priority) {
      'urgent' || 'high' => AppTheme.errorColor,
      'normal' => AppTheme.infoColor,
      'low' => Colors.grey,
      _ => Colors.grey,
    };
  }

  String _priorityLabel(String priority) {
    return switch (priority) {
      'urgent' => 'Urgente',
      'high' => 'Alta',
      'normal' => 'Normal',
      'low' => 'Baja',
      _ => priority,
    };
  }
}
