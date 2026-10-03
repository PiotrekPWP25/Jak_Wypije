import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/geo.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/transit_stop.dart';

class Departure {
  const Departure({required this.line, required this.minutes});

  final TransitLine line;

  /// Departure time on the evening axis.
  final int minutes;
}

class SafeReturnOption {
  const SafeReturnOption({
    required this.stop,
    required this.walkMeters,
    required this.walkMinutes,
    required this.departures,
  });

  final TransitStop stop;
  final double walkMeters;
  final int walkMinutes;

  /// Soonest departures after arriving at the stop, earliest first.
  final List<Departure> departures;

  bool get hasNightService => departures.any((d) => d.line.isNight);
}

/// Finds the best stop to get home from [from] when leaving at [leaveAt].
///
/// Prefers the nearest stop that still has a departure within [maxWaitMinutes]
/// after walking there; falls back to the nearest stop with any service.
SafeReturnOption? findSafeReturn({
  required LatLng from,
  required int leaveAt,
  required List<TransitStop> stops,
  int count = 3,
  int maxWaitMinutes = 45,
}) {
  final options = <SafeReturnOption>[];
  for (final stop in stops) {
    final meters = haversineMeters(from, stop.location);
    final walk = walkingMinutes(meters);
    final arriveAt = leaveAt + walk;
    final departures = [
      for (final line in stop.lines)
        for (final time in line.departuresFrom(arriveAt, limit: count))
          Departure(line: line, minutes: time),
    ]..sort((a, b) => a.minutes.compareTo(b.minutes));
    if (departures.isEmpty) continue;
    options.add(
      SafeReturnOption(
        stop: stop,
        walkMeters: meters,
        walkMinutes: walk,
        departures: List<Departure>.unmodifiable(departures.take(count)),
      ),
    );
  }
  if (options.isEmpty) return null;
  options.sort((a, b) => a.walkMeters.compareTo(b.walkMeters));
  return options.firstWhere(
    (option) =>
        option.departures.first.minutes - (leaveAt + option.walkMinutes) <=
        maxWaitMinutes,
    orElse: () => options.first,
  );
}

/// Counts planned rides home (feeds the "Bezpieczny powrót" trophy).
class SafeReturnsNotifier extends Notifier<int> {
  @override
  int build() => ref.watch(localStorageProvider).loadSafeReturns();

  Future<void> record() async {
    state = state + 1;
    await ref.read(localStorageProvider).saveSafeReturns(state);
  }
}

final safeReturnsProvider = NotifierProvider<SafeReturnsNotifier, int>(
  SafeReturnsNotifier.new,
);
