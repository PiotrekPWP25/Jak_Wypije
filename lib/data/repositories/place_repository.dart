import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/city_district.dart';
import '../models/city_event.dart';
import '../models/landmark.dart';
import '../models/place.dart';
import '../models/trip.dart';
import 'bar_repository.dart';
import 'json_asset_loader.dart';

/// Landmarks, curated trips, recurring events and the 18 city districts.
class PlaceRepository {
  const PlaceRepository(this._loader);

  final JsonAssetLoader _loader;

  Future<List<Landmark>> fetchLandmarks() async {
    final items = await _loader.loadList('assets/data/landmarks.json');
    return List<Landmark>.unmodifiable(items.map(Landmark.fromJson));
  }

  Future<List<Trip>> fetchTrips() async {
    final items = await _loader.loadList('assets/data/trips.json');
    return List<Trip>.unmodifiable(items.map(Trip.fromJson));
  }

  Future<List<CityEvent>> fetchEvents() async {
    final items = await _loader.loadList('assets/data/events.json');
    return List<CityEvent>.unmodifiable(items.map(CityEvent.fromJson));
  }

  Future<List<CityDistrict>> fetchDistricts() async {
    final items = await _loader.loadList('assets/data/districts.json');
    return List<CityDistrict>.unmodifiable(items.map(CityDistrict.fromJson));
  }
}

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepository(ref.watch(jsonAssetLoaderProvider)),
);

final landmarksProvider = FutureProvider<List<Landmark>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchLandmarks(),
);

final tripsProvider = FutureProvider<List<Trip>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchTrips(),
);

final eventsProvider = FutureProvider<List<CityEvent>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchEvents(),
);

final districtsProvider = FutureProvider<List<CityDistrict>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchDistricts(),
);

/// Bars and landmarks together – everything that can be a route stop.
final placesProvider = Provider<AsyncValue<List<Place>>>((ref) {
  final landmarks = ref.watch(landmarksProvider);
  return ref.watch(barsProvider).whenData(
        (bars) => <Place>[
          ...bars,
          ...landmarks.valueOrNull ?? const <Landmark>[],
        ],
      );
});

final placesByIdProvider = Provider<Map<String, Place>>((ref) {
  final places = ref.watch(placesProvider).valueOrNull ?? const <Place>[];
  return {for (final place in places) place.id: place};
});

final landmarkByIdProvider =
    Provider.family<AsyncValue<Landmark?>, String>((ref, id) {
  return ref.watch(landmarksProvider).whenData(
        (landmarks) => landmarks.where((l) => l.id == id).firstOrNull,
      );
});
