import 'package:latlong2/latlong.dart';

enum CrowdLevel { low, medium, high }

/// A nightlife area of the city with an hourly crowd profile.
class CityZone {
  const CityZone({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    required this.crowdByHour,
    required this.quietZone,
    required this.note,
  });

  factory CityZone.fromJson(Map<String, dynamic> json) {
    return CityZone(
      id: json['id'] as String,
      name: json['name'] as String,
      center: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      crowdByHour: List<int>.unmodifiable(
        (json['crowdByHour'] as List<dynamic>)
            .map((value) => (value as num).toInt()),
      ),
      quietZone: json['quietZone'] as bool? ?? false,
      note: json['note'] as String? ?? '',
    );
  }

  /// Hour of the first value in [crowdByHour].
  static const int firstHour = 18;

  /// Night quiet hours start at 22:00.
  static const int quietHoursFrom = 22 * 60;

  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;

  /// Crowd index 0–100 for each hour from 18:00 (index 0) to 02:00 (index 8).
  final List<int> crowdByHour;

  /// Dense residential area – keep it down after 22:00.
  final bool quietZone;
  final String note;

  /// Crowd index at [minutes] on the evening axis (clamped to the profile).
  int crowdAt(int minutes) {
    if (crowdByHour.isEmpty) return 0;
    final index = minutes ~/ 60 - firstHour;
    return crowdByHour[index.clamp(0, crowdByHour.length - 1)];
  }

  CrowdLevel levelAt(int minutes) => crowdLevelOf(crowdAt(minutes));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': center.latitude,
        'lng': center.longitude,
        'radiusMeters': radiusMeters,
        'crowdByHour': crowdByHour,
        'quietZone': quietZone,
        'note': note,
      };
}

CrowdLevel crowdLevelOf(int crowd) {
  if (crowd >= 70) return CrowdLevel.high;
  if (crowd >= 40) return CrowdLevel.medium;
  return CrowdLevel.low;
}
