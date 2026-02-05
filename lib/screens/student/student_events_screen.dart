import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/theme.dart';
import '../../services/events_service.dart';
import '../../models/event.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state.dart';

class StudentEventsScreen extends ConsumerStatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  ConsumerState<StudentEventsScreen> createState() =>
      _StudentEventsScreenState();
}

class _StudentEventsScreenState extends ConsumerState<StudentEventsScreen> {
  List<CalendarEvent> _events = [];
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      final events = await ref.read(eventsServiceProvider).getAll(
            startDate: AppDateUtils.toIso(startDate),
            endDate: AppDateUtils.toIso(endDate),
            eventType: _filterType,
          );
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group events by date
    final grouped = <String, List<CalendarEvent>>{};
    for (final event in _events) {
      final dateKey = event.startDate.split('T').first;
      grouped.putIfAbsent(dateKey, () => []).add(event);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(
                      _selectedMonth.year, _selectedMonth.month - 1));
                  _loadEvents();
                },
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _monthName(_selectedMonth),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(
                      _selectedMonth.year, _selectedMonth.month + 1));
                  _loadEvents();
                },
                icon: const Icon(LucideIcons.chevronRight),
              ),
            ]),
          ),

          // Event type filter
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _filterChip('Todos', null),
                _filterChip('Feriados', 'holiday'),
                _filterChip('Exámenes', 'exam'),
                _filterChip('Reuniones', 'meeting'),
                _filterChip('Actividades', 'activity'),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 12, children: [
              _legendDot(Colors.red, 'Feriado'),
              _legendDot(Colors.amber, 'Examen'),
              _legendDot(Colors.blue, 'Reunión'),
              _legendDot(Colors.green, 'Actividad'),
              _legendDot(Colors.grey, 'Otro'),
            ]),
          ),
          const SizedBox(height: 8),

          // Events list
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Cargando eventos...')
                : _events.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.calendar,
                        title: 'Sin eventos',
                        description: 'No hay eventos este mes.')
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: sortedDates.map((date) {
                            final dayEvents = grouped[date]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    AppDateUtils.formatDate(date),
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ...dayEvents.map((event) =>
                                    _buildEventCard(theme, event)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ThemeData theme, CalendarEvent event) {
    final color = _eventColor(event.eventType);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetail(event),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_eventIcon(event.eventType),
                  size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(_eventTypeLabel(event.eventType),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: color, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            if (event.affectsAttendance)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(LucideIcons.alertCircle,
                    size: 16, color: AppTheme.warningColor),
              ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final color = _eventColor(event.eventType);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_eventIcon(event.eventType),
                      color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(event.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 16),
              _detailRow(theme, LucideIcons.tag,
                  _eventTypeLabel(event.eventType)),
              _detailRow(theme, LucideIcons.calendar,
                  AppDateUtils.formatDate(event.startDate)),
              if (event.endDate != null)
                _detailRow(theme, LucideIcons.calendarCheck,
                    'Hasta: ${AppDateUtils.formatDate(event.endDate!)}'),
              if (event.affectsAttendance)
                _detailRow(theme, LucideIcons.alertCircle,
                    'Afecta la asistencia'),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(event.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(text, style: theme.textTheme.bodyMedium),
      ]),
    );
  }

  Widget _filterChip(String label, String? type) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filterType == type,
        onSelected: (_) {
          setState(() => _filterType = type);
          _loadEvents();
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }

  Color _eventColor(String type) {
    return switch (type) {
      'holiday' => Colors.red,
      'exam' => Colors.amber.shade700,
      'meeting' => Colors.blue,
      'activity' => Colors.green,
      _ => Colors.grey,
    };
  }

  IconData _eventIcon(String type) {
    return switch (type) {
      'holiday' => LucideIcons.palmtree,
      'exam' => LucideIcons.fileText,
      'meeting' => LucideIcons.users,
      'activity' => LucideIcons.flag,
      _ => LucideIcons.calendar,
    };
  }

  String _eventTypeLabel(String type) {
    return switch (type) {
      'holiday' => 'Feriado',
      'exam' => 'Examen',
      'meeting' => 'Reunión',
      'activity' => 'Actividad',
      'other' => 'Otro',
      _ => type,
    };
  }

  String _monthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
