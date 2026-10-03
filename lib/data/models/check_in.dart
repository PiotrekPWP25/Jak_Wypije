import 'place.dart';

enum CheckInMethod { qr, gps, demo }

class CheckIn {
  const CheckIn({
    required this.placeId,
    required this.timestamp,
    required this.points,
    required this.method,
    this.placeType = PlaceType.bar,
    this.districtNo = 0,
    this.offPeak = false,
    this.completedRoute = false,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      // `barId` is the pre-v3 key.
      placeId: (json['placeId'] ?? json['barId']) as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      points: (json['points'] as num).toInt(),
      method: CheckInMethod.values.byName(json['method'] as String? ?? 'qr'),
      placeType: PlaceType.values.byName(json['placeType'] as String? ?? 'bar'),
      districtNo: (json['districtNo'] as num?)?.toInt() ?? 0,
      offPeak: json['offPeak'] as bool? ?? false,
      completedRoute: json['completedRoute'] as bool? ?? false,
    );
  }

  final String placeId;
  final DateTime timestamp;
  final int points;
  final CheckInMethod method;
  final PlaceType placeType;

  /// Kraków district (1–18) of the place; 0 when unknown (old data).
  final int districtNo;

  /// Visit outside a crowded zone (helps spread the nightlife).
  final bool offPeak;

  /// This check-in finished the planned route.
  final bool completedRoute;

  bool get isBar => placeType == PlaceType.bar;

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'timestamp': timestamp.toIso8601String(),
        'points': points,
        'method': method.name,
        'placeType': placeType.name,
        'districtNo': districtNo,
        'offPeak': offPeak,
        'completedRoute': completedRoute,
      };
}
