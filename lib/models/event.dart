class CalendarEvent {
  final int id;
  final String title;
  final String? description;
  final String eventType;
  final String startDate;
  final String? endDate;
  final bool isRecurring;
  final String? recurrencePattern;
  final bool affectsAttendance;
  final int? academicPeriodId;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.startDate,
    this.endDate,
    this.isRecurring = false,
    this.recurrencePattern,
    this.affectsAttendance = false,
    this.academicPeriodId,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ?? 'other',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      affectsAttendance: json['affects_attendance'] as bool? ?? false,
      academicPeriodId: json['academic_period_id'] as int?,
    );
  }
}
