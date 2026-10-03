import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/bar.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
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

/// Previous (last) bar on the Barobranie route, else the user, else Rynek.
final referencePointProvider = Provider<ReferencePoint>((ref) {
  final mode = ref.watch(distanceReferenceProvider);
  final position = ref.watch(userPositionProvider).valueOrNull;
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
      final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
      if (plan.barIds.isEmpty) return me;
      final last = bars.where((bar) => bar.id == plan.barIds.last).firstOrNull;
      return last == null ? me : (point: last.location, label: last.name);
  }
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
