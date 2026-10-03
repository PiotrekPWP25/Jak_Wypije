import '../../core/utils/geo.dart';
import '../../data/models/bar.dart';
import '../../data/models/evening_plan.dart';

class PlanStop {
  const PlanStop({
    required this.bar,
    required this.walkMeters,
    required this.walkMinutes,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.cost,
  });

  final Bar bar;

  /// Walk from the previous stop (0 for the first one).
  final double walkMeters;
  final int walkMinutes;
  final int arrivalMinutes;
  final int departureMinutes;
  final double cost;
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
  final double totalCost;
  final int endMinutes;
}

/// Bars from [plan] in plan order, skipping unknown ids.
List<Bar> resolveStops(EveningPlan plan, List<Bar> bars) {
  final byId = {for (final bar in bars) bar.id: bar};
  return plan.barIds.map((id) => byId[id]).nonNulls.toList();
}

/// Builds the evening timeline: walking legs, arrival times and budget.
PlanSummary calculatePlan(EveningPlan plan, List<Bar> bars) {
  final stops = <PlanStop>[];
  var clock = plan.startMinutes;
  var totalMeters = 0.0;
  var totalWalk = 0;
  var totalCost = 0.0;

  for (var i = 0; i < bars.length; i++) {
    final bar = bars[i];
    final meters =
        i == 0 ? 0.0 : haversineMeters(bars[i - 1].location, bar.location);
    final walk = walkingMinutes(meters);
    clock += walk;
    final arrival = clock;
    clock += plan.minutesPerStop;
    final cost = bar.beerPrice * plan.drinksPerStop;

    totalMeters += meters;
    totalWalk += walk;
    totalCost += cost;
    stops.add(
      PlanStop(
        bar: bar,
        walkMeters: meters,
        walkMinutes: walk,
        arrivalMinutes: arrival,
        departureMinutes: clock,
        cost: cost,
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
