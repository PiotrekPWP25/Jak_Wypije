import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../models/city_zone.dart';
import '../models/transit_stop.dart';
import 'json_asset_loader.dart';

/// Urban data: nightlife zones (crowds, quiet hours) and public transport.
///
/// Mock JSON today; designed to be fed from city open data (ZTP Kraków GTFS,
/// anonymised check-in counts) without changing the UI.
class CityRepository {
  const CityRepository(this._loader);

  final JsonAssetLoader _loader;

  Future<List<CityZone>> fetchZones() async {
    final items = await _loader.loadList('assets/data/city_zones.json');
    return List<CityZone>.unmodifiable(items.map(CityZone.fromJson));
  }

  Future<List<TransitStop>> fetchTransitStops() async {
    final items = await _loader.loadList('assets/data/transit_stops.json');
    return List<TransitStop>.unmodifiable(items.map(TransitStop.fromJson));
  }
}

final cityRepositoryProvider = Provider<CityRepository>(
  (ref) => CityRepository(ref.watch(jsonAssetLoaderProvider)),
);

final zonesProvider = FutureProvider<List<CityZone>>(
  (ref) => ref.watch(cityRepositoryProvider).fetchZones(),
);

final zonesByIdProvider = Provider<Map<String, CityZone>>((ref) {
  final zones = ref.watch(zonesProvider).valueOrNull ?? const <CityZone>[];
  return {for (final zone in zones) zone.id: zone};
});

final transitStopsProvider = FutureProvider<List<TransitStop>>(
  (ref) => ref.watch(cityRepositoryProvider).fetchTransitStops(),
);

/// Time used for live city data; refreshed when the app restarts.
final cityClockProvider = Provider<CityClock>(
  (ref) => CityClock.of(DateTime.now()),
);
