import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/models/bar.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import '../../data/models/price_range.dart';

enum PlanWarningType { closed, closesEarly, crowded, quietZone }

class PlanWarning {
  const PlanWarning({required this.type, required this.message});

  final PlanWarningType type;
  final String message;
}

class PlanStop {
  const PlanStop({
    required this.place,
    required this.walkMeters,
    required this.walkMinutes,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.cost,
    this.warnings = const [],
  });

  final Place place;

  /// Walk from the previous stop (0 for the first one).
  final double walkMeters;
  final int walkMinutes;
  final int arrivalMinutes;
  final int departureMinutes;

  /// Drinks in a bar or the ticket of a landmark.
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

  int get landmarkCount => stops.where((s) => s.place is Landmark).length;
}

/// Places from [plan] in plan order, skipping unknown ids.
List<Place> resolveStops(EveningPlan plan, Map<String, Place> placesById) =>
    plan.stopIds.map((id) => placesById[id]).nonNulls.toList();

/// Builds the route timeline: walking legs, arrival times, budget range and
/// city-aware warnings (opening hours, crowds, quiet hours).
PlanSummary calculatePlan(
  EveningPlan plan,
  List<Place> places, {
  Map<String, CityZone> zones = const {},
}) {
  final stops = <PlanStop>[];
  var clock = plan.startMinutes;
  var totalMeters = 0.0;
  var totalWalk = 0;
  var totalCost = PriceRange.zero;

  for (var i = 0; i < places.length; i++) {
    final place = places[i];
    final meters =
        i == 0 ? 0.0 : haversineMeters(places[i - 1].location, place.location);
    final walk = walkingMinutes(meters);
    clock += walk;
    final arrival = clock;
    final PriceRange cost;
    switch (place) {
      case Landmark():
        clock += place.visitMinutes;
        cost = place.ticket ?? PriceRange.zero;
      case Bar():
        clock += plan.minutesPerStop;
        cost = place.beer * plan.drinksPerStop;
      default:
        clock += plan.minutesPerStop;
        cost = PriceRange.zero;
    }

    totalMeters += meters;
    totalWalk += walk;
    totalCost = totalCost + cost;
    stops.add(
      PlanStop(
        place: place,
        walkMeters: meters,
        walkMinutes: walk,
        arrivalMinutes: arrival,
        departureMinutes: clock,
        cost: cost,
        warnings: _warningsFor(
          place,
          arrival: arrival,
          departure: clock,
          zone: zones[place.zoneId],
          isLast: i == places.length - 1,
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

int? _closesAt(Place place) => switch (place) {
      Bar() => place.closesAt,
      Landmark() => place.closesAt,
      _ => null,
    };

String _hours(Place place) => switch (place) {
      Bar() => place.openHours,
      Landmark() => place.openHours,
      _ => '',
    };

List<PlanWarning> _warningsFor(
  Place place, {
  required int arrival,
  required int departure,
  required CityZone? zone,
  required bool isLast,
}) {
  final warnings = <PlanWarning>[];
  final closesAt = _closesAt(place);
  if (!place.isOpenAt(arrival)) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.closed,
        message: 'O ${formatClock(arrival)} będzie zamknięte '
            '(${_hours(place)}).',
      ),
    );
  } else if (closesAt != null && departure > closesAt) {
    warnings.add(
      PlanWarning(
        type: PlanWarningType.closesEarly,
        message: 'Zamykają o ${formatClock(closesAt)} – '
            'skróć postój albo zamień kolejność.',
      ),
    );
  }
  if (place is Bar &&
      zone != null &&
      zone.levelAt(arrival) == CrowdLevel.high) {
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
List<String> optimizeRoute(List<Place> places) {
  if (places.length < 3) return [for (final place in places) place.id];
  final remaining = [...places.skip(1)];
  final route = [places.first];
  while (remaining.isNotEmpty) {
    final last = route.last.location;
    remaining.sort(
      (a, b) => haversineMeters(last, a.location)
          .compareTo(haversineMeters(last, b.location)),
    );
    route.add(remaining.removeAt(0));
  }
  return [for (final place in route) place.id];
}

/// Calmer alternative for a crowded bar: nearest hidden gem in a low-crowd
/// zone that is not already planned.
Bar? calmerAlternative(
  Place crowded,
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
