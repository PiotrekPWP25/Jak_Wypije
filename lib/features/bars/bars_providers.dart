import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../barobranie/planner_controller.dart';
import '../friends/reviews_controller.dart';
import 'bar_filters.dart';

/// What distances in the bar list are measured from.
enum DistanceReference { lastStop, me, center }

class DistanceReferenceNotifier extends Notifier<DistanceReference> {
  @override
  DistanceReference build() => DistanceReference.lastStop;

  void set(DistanceReference reference) => state = reference;
}

final distanceReferenceProvider =
    NotifierProvider<DistanceReferenceNotifier, DistanceReference>(
  DistanceReferenceNotifier.new,
);

typedef ReferencePoint = ({LatLng point, String label});

/// Beyond this distance from Rynek the user is not in Kraków (e.g. planning
/// a trip from home), so distances are measured from the centre instead.
const double cityRadiusMeters = 30000;

/// [position] if it is in Kraków, else `null`.
LatLng? positionInCity(LatLng? position) => position == null ||
        haversineMeters(position, krakowCenter) > cityRadiusMeters
    ? null
    : position;

/// Previous (last) bar on the Barobranie route, else the user, else Rynek.
final referencePointProvider = Provider<ReferencePoint>((ref) {
  final mode = ref.watch(distanceReferenceProvider);
  final position = positionInCity(ref.watch(userPositionProvider).valueOrNull);
  const center = (point: krakowCenter, label: 'Rynek Główny');
  final me =
      position == null ? center : (point: position, label: 'Twoja lokalizacja');

  switch (mode) {
    case DistanceReference.center:
      return center;
    case DistanceReference.me:
      return me;
    case DistanceReference.lastStop:
      final plan = ref.watch(plannerProvider);
      if (plan.stopIds.isEmpty) return me;
      final last = ref.watch(placesByIdProvider)[plan.stopIds.last];
      return last == null ? me : (point: last.location, label: last.name);
  }
});

/// Which list the "Bary" tab shows.
class ShowLandmarksNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final showLandmarksProvider = NotifierProvider<ShowLandmarksNotifier, bool>(
  ShowLandmarksNotifier.new,
);

/// Landmarks with distance from the reference point and "open now".
final landmarkListingsProvider =
    Provider<AsyncValue<List<LandmarkListing>>>((ref) {
  final reference = ref.watch(referencePointProvider);
  final clock = ref.watch(cityClockProvider);
  return ref.watch(landmarksProvider).whenData(
        (landmarks) => buildLandmarkListings(
          landmarks: landmarks,
          reference: reference.point,
          nowMinutes: clock.minutes,
        ),
      );
});

class BarFiltersNotifier extends Notifier<BarFilters> {
  @override
  BarFilters build() => const BarFilters();

  void update(BarFilters filters) => state = filters;

  void clear() => state = state.cleared();
}

final barFiltersProvider = NotifierProvider<BarFiltersNotifier, BarFilters>(
  BarFiltersNotifier.new,
);

/// All bars with distance, friends' rating, crowd and "open now".
final barListingsProvider = Provider<AsyncValue<List<BarListing>>>((ref) {
  final reviews = ref.watch(allReviewsProvider).valueOrNull ?? const <Review>[];
  final zones = ref.watch(zonesByIdProvider);
  final clock = ref.watch(cityClockProvider);
  final reference = ref.watch(referencePointProvider);
  return ref.watch(barsProvider).whenData(
        (bars) => buildListings(
          bars: bars,
          reviews: reviews,
          reference: reference.point,
          zones: zones,
          nowMinutes: clock.minutes,
        ),
      );
});

final filteredListingsProvider = Provider<AsyncValue<List<BarListing>>>((ref) {
  final filters = ref.watch(barFiltersProvider);
  return ref.watch(barListingsProvider).whenData(
        (listings) =>
            sortListings(applyFilters(listings, filters), filters.sort),
      );
});
