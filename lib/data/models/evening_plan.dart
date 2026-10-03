/// The user's plan for the evening: an ordered list of bars.
class EveningPlan {
  const EveningPlan({
    required this.barIds,
    required this.startMinutes,
    required this.minutesPerStop,
    required this.drinksPerStop,
  });

  factory EveningPlan.fromJson(Map<String, dynamic> json) {
    return EveningPlan(
      barIds: List<String>.unmodifiable(
        (json['barIds'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      ),
      startMinutes:
          (json['startMinutes'] as num?)?.toInt() ?? initial.startMinutes,
      minutesPerStop:
          (json['minutesPerStop'] as num?)?.toInt() ?? initial.minutesPerStop,
      drinksPerStop:
          (json['drinksPerStop'] as num?)?.toInt() ?? initial.drinksPerStop,
    );
  }

  static const EveningPlan initial = EveningPlan(
    barIds: <String>[],
    startMinutes: 19 * 60,
    minutesPerStop: 60,
    drinksPerStop: 2,
  );

  final List<String> barIds;

  /// Start time as minutes from midnight.
  final int startMinutes;
  final int minutesPerStop;
  final int drinksPerStop;

  EveningPlan copyWith({
    List<String>? barIds,
    int? startMinutes,
    int? minutesPerStop,
    int? drinksPerStop,
  }) {
    return EveningPlan(
      barIds:
          barIds == null ? this.barIds : List<String>.unmodifiable(barIds),
      startMinutes: startMinutes ?? this.startMinutes,
      minutesPerStop: minutesPerStop ?? this.minutesPerStop,
      drinksPerStop: drinksPerStop ?? this.drinksPerStop,
    );
  }

  Map<String, dynamic> toJson() => {
        'barIds': barIds,
        'startMinutes': startMinutes,
        'minutesPerStop': minutesPerStop,
        'drinksPerStop': drinksPerStop,
      };
}
