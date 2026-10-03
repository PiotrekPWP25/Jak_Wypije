/// The user's plan for the evening: an ordered list of places (bars and
/// landmarks).
class EveningPlan {
  const EveningPlan({
    required this.stopIds,
    required this.startMinutes,
    required this.minutesPerStop,
    required this.drinksPerStop,
  });

  factory EveningPlan.fromJson(Map<String, dynamic> json) {
    // `barIds` is the pre-v3 key – keep reading it so saved plans survive.
    final ids = json['stopIds'] ?? json['barIds'];
    return EveningPlan(
      stopIds: List<String>.unmodifiable(
        (ids as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
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
    stopIds: <String>[],
    startMinutes: 19 * 60,
    minutesPerStop: 60,
    drinksPerStop: 2,
  );

  final List<String> stopIds;

  /// Start time as minutes from midnight.
  final int startMinutes;

  /// Time spent in each bar (landmarks use their own visit time).
  final int minutesPerStop;

  /// Drinks per bar – only used for the budget estimate.
  final int drinksPerStop;

  EveningPlan copyWith({
    List<String>? stopIds,
    int? startMinutes,
    int? minutesPerStop,
    int? drinksPerStop,
  }) {
    return EveningPlan(
      stopIds:
          stopIds == null ? this.stopIds : List<String>.unmodifiable(stopIds),
      startMinutes: startMinutes ?? this.startMinutes,
      minutesPerStop: minutesPerStop ?? this.minutesPerStop,
      drinksPerStop: drinksPerStop ?? this.drinksPerStop,
    );
  }

  Map<String, dynamic> toJson() => {
        'stopIds': stopIds,
        'startMinutes': startMinutes,
        'minutesPerStop': minutesPerStop,
        'drinksPerStop': drinksPerStop,
      };
}
