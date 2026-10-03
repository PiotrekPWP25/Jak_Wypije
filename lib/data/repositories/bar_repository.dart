import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bar.dart';
import 'json_asset_loader.dart';

class BarRepository {
  const BarRepository(this._loader);

  final JsonAssetLoader _loader;

  Future<List<Bar>> fetchBars() async {
    final items = await _loader.loadList('assets/data/bars.json');
    return List<Bar>.unmodifiable(items.map(Bar.fromJson));
  }
}

final barRepositoryProvider = Provider<BarRepository>(
  (ref) => BarRepository(ref.watch(jsonAssetLoaderProvider)),
);

final barsProvider = FutureProvider<List<Bar>>(
  (ref) => ref.watch(barRepositoryProvider).fetchBars(),
);

final barByIdProvider = Provider.family<AsyncValue<Bar?>, String>((ref, id) {
  return ref
      .watch(barsProvider)
      .whenData((bars) => bars.where((bar) => bar.id == id).firstOrNull);
});
