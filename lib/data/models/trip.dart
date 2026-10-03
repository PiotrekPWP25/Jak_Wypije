import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';

enum TripAudience { tourist, local, both }

/// A curated route mixing landmarks and bars (like a Google Maps list).
class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.audience,
    required this.stopIds,
    required this.startMinutes,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🗺️',
      audience: TripAudience.values.byName(json['audience'] as String),
      stopIds: List<String>.unmodifiable(
        (json['stopIds'] as List<dynamic>).cast<String>(),
      ),
      startMinutes: parseEveningTime(json['startTime'] as String),
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final TripAudience audience;
  final List<String> stopIds;
  final int startMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'emoji': emoji,
        'audience': audience.name,
        'stopIds': stopIds,
        'startTime': formatClock(startMinutes),
      };
}
