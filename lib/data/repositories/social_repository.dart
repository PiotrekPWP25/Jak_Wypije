import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friend.dart';
import '../models/review.dart';
import 'json_asset_loader.dart';

class SocialRepository {
  const SocialRepository(this._loader);

  final JsonAssetLoader _loader;

  Future<List<Friend>> fetchFriends() async {
    final items = await _loader.loadList('assets/data/friends.json');
    return List<Friend>.unmodifiable(items.map(Friend.fromJson));
  }

  Future<List<Review>> fetchFriendReviews() async {
    final items = await _loader.loadList('assets/data/reviews.json');
    return List<Review>.unmodifiable(items.map(Review.fromJson));
  }
}

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(ref.watch(jsonAssetLoaderProvider)),
);

final friendsProvider = FutureProvider<List<Friend>>(
  (ref) => ref.watch(socialRepositoryProvider).fetchFriends(),
);

final friendReviewsProvider = FutureProvider<List<Review>>(
  (ref) => ref.watch(socialRepositoryProvider).fetchFriendReviews(),
);
