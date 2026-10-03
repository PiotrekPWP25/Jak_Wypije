import '../../core/utils/geo.dart';
import '../../core/utils/time.dart';
import '../../data/models/bar.dart';
import '../../data/models/check_in.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';

/// Points reward exploring the city – landmarks, new districts, walking and
/// finished routes – not the number of bars. Only the first
/// [scoredBarsPerEvening] bar check-ins of an evening earn points.
abstract final class Scoring {
  static const int landmarkBase = 15;
  static const int landmarkFirstVisit = 5;
  static const int barBase = 10;
  static const int hiddenGemBonus = 5;
  static const int offPeakBonus = 10;
  static const int newDistrictBonus = 20;
  static const int routeBonus = 30;
  static const int scoredBarsPerEvening = 2;
  static const int xpPerKm = 10;
  static const double maxWalkMetersPerEvening = 6000;
}

class ScoreResult {
  const ScoreResult({
    required this.points,
    required this.bonuses,
    required this.offPeak,
    required this.completedRoute,
  });

  final int points;
  final List<String> bonuses;
  final bool offPeak;
  final bool completedRoute;
}

/// An "evening" lasts until 6 a.m. of the next day.
bool isSameEvening(DateTime a, DateTime b) {
  const shift = Duration(hours: 6);
  final x = a.subtract(shift);
  final y = b.subtract(shift);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// District of a check-in, also for pre-v3 data without `districtNo`.
int districtOf(CheckIn checkIn, Map<String, Place> placesById) =>
    checkIn.districtNo > 0
        ? checkIn.districtNo
        : placesById[checkIn.placeId]?.districtNo ?? 0;

ScoreResult scoreCheckIn({
  required Place place,
  required List<CheckIn> history,
  required DateTime at,
  required Map<String, Place> placesById,
  CityZone? zone,
  EveningPlan? plan,
}) {
  final tonight =
      history.where((checkIn) => isSameEvening(checkIn.timestamp, at)).toList();
  final offPeak =
      zone != null && zone.levelAt(eveningMinutes(at)) == CrowdLevel.low;
  var points = 0;
  final bonuses = <String>[];
  var capped = false;

  if (place is Landmark) {
    points += Scoring.landmarkBase;
    bonuses.add('Atrakcja +${Scoring.landmarkBase}');
    if (!history.any((checkIn) => checkIn.placeId == place.id)) {
      points += Scoring.landmarkFirstVisit;
      bonuses.add('Pierwsza wizyta +${Scoring.landmarkFirstVisit}');
    }
  } else if (place is Bar) {
    final barsTonight = tonight.where((checkIn) => checkIn.isBar).length;
    if (barsTonight >= Scoring.scoredBarsPerEvening) {
      capped = true;
      bonuses.add(
        'Punktujemy ${Scoring.scoredBarsPerEvening} bary na wieczór – '
        'kolejne punkty zdobędziesz za spacer i atrakcje',
      );
    } else {
      points += Scoring.barBase;
      bonuses.add('Meldunek +${Scoring.barBase}');
      if (place.isHiddenGem) {
        points += Scoring.hiddenGemBonus;
        bonuses.add('Ukryta perełka +${Scoring.hiddenGemBonus}');
      }
      if (offPeak) {
        points += Scoring.offPeakBonus;
        bonuses.add('Poza tłokiem +${Scoring.offPeakBonus}');
      }
    }
  }

  final districtNo = place.districtNo;
  final newDistrict = districtNo > 0 &&
      !history.any((checkIn) => districtOf(checkIn, placesById) == districtNo);
  if (newDistrict && !capped) {
    points += Scoring.newDistrictBonus;
    bonuses.add(
      'Nowa dzielnica (${place.district}) +${Scoring.newDistrictBonus}',
    );
  }

  final completedRoute = _completesRoute(place, tonight, placesById, plan);
  if (completedRoute) {
    points += Scoring.routeBonus;
    bonuses.add('Trasa ukończona +${Scoring.routeBonus}');
  }

  return ScoreResult(
    points: points,
    bonuses: List<String>.unmodifiable(bonuses),
    offPeak: offPeak,
    completedRoute: completedRoute,
  );
}

/// The route counts as finished when this check-in is its last unvisited
/// stop tonight and it contains at least one landmark (a walk, not a crawl).
bool _completesRoute(
  Place place,
  List<CheckIn> tonight,
  Map<String, Place> placesById,
  EveningPlan? plan,
) {
  if (plan == null || plan.stopIds.length < 2) return false;
  if (!plan.stopIds.contains(place.id)) return false;
  if (tonight.any((checkIn) => checkIn.completedRoute)) return false;
  if (!plan.stopIds.any((id) => placesById[id] is Landmark)) return false;
  return plan.stopIds
      .where((id) => id != place.id)
      .every((id) => tonight.any((checkIn) => checkIn.placeId == id));
}

/// Walking distance between consecutive check-ins of each evening, capped
/// per evening so the number stays realistic.
double walkedMeters(
  Iterable<CheckIn> checkIns,
  Map<String, Place> placesById,
) {
  final sorted = [...checkIns]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  var total = 0.0;
  var evening = 0.0;
  CheckIn? previous;
  for (final checkIn in sorted) {
    final last = previous;
    if (last == null || !isSameEvening(last.timestamp, checkIn.timestamp)) {
      total += evening;
      evening = 0;
    } else {
      final from = placesById[last.placeId]?.location;
      final to = placesById[checkIn.placeId]?.location;
      if (from != null && to != null) {
        evening = (evening + haversineMeters(from, to))
            .clamp(0, Scoring.maxWalkMetersPerEvening)
            .toDouble();
      }
    }
    previous = checkIn;
  }
  return total + evening;
}

int walkingXp(double meters) => (meters / 1000 * Scoring.xpPerKm).floor();

/// Districts stamped in the passport.
Set<int> stampedDistricts(
  Iterable<CheckIn> checkIns,
  Map<String, Place> placesById,
) =>
    {
      for (final checkIn in checkIns) districtOf(checkIn, placesById),
    }..remove(0);
