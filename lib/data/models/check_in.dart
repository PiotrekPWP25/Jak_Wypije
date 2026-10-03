enum CheckInMethod { qr, gps, demo }

class CheckIn {
  const CheckIn({
    required this.barId,
    required this.timestamp,
    required this.points,
    required this.method,
    this.offPeak = false,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      barId: json['barId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      points: (json['points'] as num).toInt(),
      method: CheckInMethod.values.byName(json['method'] as String? ?? 'qr'),
      offPeak: json['offPeak'] as bool? ?? false,
    );
  }

  final String barId;
  final DateTime timestamp;
  final int points;
  final CheckInMethod method;

  /// Visit to a bar outside a crowded zone (helps spread the nightlife).
  final bool offPeak;

  Map<String, dynamic> toJson() => {
        'barId': barId,
        'timestamp': timestamp.toIso8601String(),
        'points': points,
        'method': method.name,
        'offPeak': offPeak,
      };
}
