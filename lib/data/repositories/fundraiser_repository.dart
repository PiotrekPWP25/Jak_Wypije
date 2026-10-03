import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fundraiser.dart';
import 'json_asset_loader.dart';

class FundraiserRepository {
  const FundraiserRepository(this._loader);

  final JsonAssetLoader _loader;

  Future<List<Fundraiser>> fetchFundraisers() async {
    final items = await _loader.loadList('assets/data/fundraisers.json');
    return List<Fundraiser>.unmodifiable(items.map(Fundraiser.fromJson));
  }
}

final fundraiserRepositoryProvider = Provider<FundraiserRepository>(
  (ref) => FundraiserRepository(ref.watch(jsonAssetLoaderProvider)),
);

/// Fundraisers as shipped in the mock data (without local pledges).
final baseFundraisersProvider = FutureProvider<List<Fundraiser>>(
  (ref) => ref.watch(fundraiserRepositoryProvider).fetchFundraisers(),
);
