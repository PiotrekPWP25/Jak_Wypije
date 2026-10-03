import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/models/bar.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/price_range.dart';

enum PlanWarningType { closed, closesEarly, crowded, quietZone }

class PlanWarning {
  const PlanWarning({required this.type, required this.message});

  final PlanWarningType type;
  final String message;
}

class PlanStop {
  const PlanStop({
    required this.bar,
    required this.walkMeters,
    required this.walkMinutes,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.cost,
    this.warnings = const [],
  });

  final Bar bar;

  /// Walk from the previous stop (0 for the first one).
  final double walkMeters;
  final int walkMinutes;
  final int arrivalMinutes;
  final int departureMinutes;

  /// Drinks at this stop as a price range.
  final PriceRange cost;
  final List<PlanWarning> warnings;
}

class PlanSummary {
  const PlanSummary({
    required this.stops,
    required this.totalWalkMeters,
    required this.totalWalkMinutes,
    required this.totalCost,
    required this.endMinutes,
  });

  final List<PlanStop> stops;
  final double totalWalkMeters;
  final int totalWalkMinutes;
  final PriceRange totalCost;
  final int endMinutes;

  int get warningCount =>
      stops.fold(0, (sum, stop) => sum + stop.warnings.length);
}

/// Bars from [plan] in plan order, skipping unknown ids.
List<Bar> resolveStops(EveningPlan plan, List<Bar> bars) {
  final byId = {for (final bar in bars) bar.id: bar};
  return plan.barIds.map((id) => byId[id]).nonNulls.toList();
}

/// Builds the evening timeline: walking legs, arrival times, budget range
/// and city-aware warnings (opening hours, crowds, quiet hours).
PlanSummary calculatePlan(
  EveningPlan plan,
  List<Bar> bars, {
  Map<String, CityZone> zones = const {},
}) {
  final stops = <PlanStop>[];
  var clock = plan.startMinutes;
  var totalMeters = 0.0;
  var totalWalk = 0;
  var totalCost = PriceRange.zero;

  for (var i = 0; i < bars.length; i++) {
    final bar = bars[i];
    final meters =
        i == 0 ? 0.0 : haversineMeters(bars[i - 1].location, bar.location);
    final walk = walkingMinutes(meters);
    clock += walk;
    final arrival = clock;
    clock += plan.minutesPerStop;
    final cost = bar.beer * plan.drinksPerStop;
    final isLast = i == bars.length - 1;

    totalMeters += meters;
    totalWalk += walk;
    totalCost = totalCost + cost;
    stops.add(
      PlanStop(
        bar: bar,
        walkMeters: meters,
        walkMinutes: walk,
        arrivalMinutes: arrival,
        departureMinutes: clock,
        cost: cost,
        warnings: _warningsFor(
          bar,
          arrival: arrival,
          departure: clock,
          zone: zones[bar.zoneId],
          isLast: isLast,
        ),
      ),
    );
  }

  return PlanSummary(
    stops: List<PlanStop>.unmodifiable(stops),
    totalWalkMeters: totalMeters,
    totalWalkMinutes: totalWalk,
    totalCost: totalCost,
    endMinutes: clock,
  );
}

List<PlanWarning> _warningsFor(
  Bar bar, {
  required int arrival,
  required int departure,
  required CityZone? zone,
  required bool isLast,
}) {
  final warnings = <PlanWarning>[];
  if (!bar.isOpenAt(arrival)) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.closed,
        message: 'O ${formatClock(arrival)} będzie zamknięte '
            '(${bar.openHours}).',
      ),
    );
  } else if (departure > bar.closesAt) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.closesEarly,
        message: 'Zamykają o ${formatClock(bar.closesAt)} – '
            'skróć postój albo zamień kolejność.',
      ),
    );
  }
  if (zone != null && zone.levelAt(arrival) == CrowdLevel.high) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.crowded,
        message: '${zone.name} o ${formatClock(arrival)} jest zatłoczony – '
            'rozważ perełkę poza centrum.',
      ),
    );
  }
  if (isLast &&
      zone != null &&
      zone.quietZone &&
      departure >= CityZone.quietHoursFrom) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.quietZone,
        message: 'Kończysz w strefie ciszy nocnej (${zone.name}) – '
            'wychodząc, szanuj sen mieszkańców.',
      ),
    );
  }
  return List<PlanWarning>.unmodifiable(warnings);
}

/// Greedy nearest-neighbour route that keeps the first stop in place.
List<String> optimizeRoute(List<Bar> bars) {
  if (bars.length < 3) return [for (final bar in bars) bar.id];
  final remaining = [...bars.skip(1)];
  final route = [bars.first];
  while (remaining.isNotEmpty) {
    final last = route.last.location;
    remaining.sort(
      (a, b) => haversineMeters(last, a.location)
          .compareTo(haversineMeters(last, b.location)),
    );
    route.add(remaining.removeAt(0));
  }
  return [for (final bar in route) bar.id];
}

/// Calmer alternative for a crowded stop: nearest hidden gem in a low-crowd
/// zone that is not already planned.
Bar? calmerAlternative(
  Bar crowded,
  List<Bar> bars,
  Map<String, CityZone> zones, {
  required int atMinutes,
  required Set<String> excludeIds,
  double maxMeters = 2000,
}) {
  Bar? best;
  var bestDistance = maxMeters;
  for (final bar in bars) {
    if (excludeIds.contains(bar.id) || !bar.isOpenAt(atMinutes)) continue;
    final zone = zones[bar.zoneId];
    if (zone == null || zone.levelAt(atMinutes) != CrowdLevel.low) continue;
    final distance = haversineMeters(crowded.location, bar.location);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = bar;
    }
  }
  return best;
}
