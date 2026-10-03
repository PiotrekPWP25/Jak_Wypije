import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';

/// A recurring weekly event at a place (sample data).
class CityEvent {
  const CityEvent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.placeId,
    required this.description,
  });

  factory CityEvent.fromJson(Map<String, dynamic> json) {
    return CityEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🎉',
      weekday: (json['weekday'] as num).toInt(),
      startMinutes: parseEveningTime(json['start'] as String),
      endMinutes: parseEveningTime(json['end'] as String),
      placeId: json['placeId'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String emoji;

  /// [DateTime.monday] (1) … [DateTime.sunday] (7).
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String placeId;
  final String description;

  String get hours => '${formatClock(startMinutes)}–${formatClock(endMinutes)}';

  /// Start of the next occurrence that has not ended yet.
  DateTime nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset <= 7; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      if (day.weekday != weekday) continue;
      final end = DateTime(day.year, day.month, day.day, 0, endMinutes);
      if (end.isAfter(now)) {
        return DateTime(day.year, day.month, day.day, 0, startMinutes);
      }
    }
    return DateTime(today.year, today.month, today.day + 7, 0, startMinutes);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'weekday': weekday,
        'start': formatClock(startMinutes),
        'end': formatClock(endMinutes),
        'placeId': placeId,
        'description': description,
      };
}

typedef UpcomingEvent = ({CityEvent event, DateTime at});

/// Occurrences within the next [days] days, soonest first.
List<UpcomingEvent> upcomingEvents(
  List<CityEvent> events,
  DateTime now, {
  int days = 7,
}) {
  final limit = now.add(Duration(days: days));
  final result = [
    for (final event in events) (event: event, at: event.nextOccurrence(now)),
  ].where((e) => e.at.isBefore(limit)).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  return result;
}
