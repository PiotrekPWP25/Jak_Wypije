import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/friend.dart';
import '../../data/models/review.dart';
import '../../data/repositories/social_repository.dart';

/// Reviews written by the current user (stored locally).
class MyReviewsNotifier extends Notifier<List<Review>> {
  static const int pointsPerReview = 5;

  @override
  List<Review> build() => ref.watch(localStorageProvider).loadMyReviews();

  void add({
    required String barId,
    required int rating,
    required String comment,
  }) {
    final now = DateTime.now();
    final review = Review(
      id: 'my-${now.microsecondsSinceEpoch}',
      barId: barId,
      authorId: Review.myAuthorId,
      rating: rating,
      comment: comment.trim(),
      createdAt: now,
    );
    state = List<Review>.unmodifiable([review, ...state]);
    ref.read(localStorageProvider).saveMyReviews(state);
  }
}

final myReviewsProvider = NotifierProvider<MyReviewsNotifier, List<Review>>(
  MyReviewsNotifier.new,
);

/// Friends' mock reviews plus the user's own, newest first.
final allReviewsProvider = Provider<AsyncValue<List<Review>>>((ref) {
  final mine = ref.watch(myReviewsProvider);
  return ref.watch(friendReviewsProvider).whenData((friendReviews) {
    final all = [...mine, ...friendReviews]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<Review>.unmodifiable(all);
  });
});

final friendsByIdProvider = Provider<Map<String, Friend>>((ref) {
  final friends = ref.watch(friendsProvider).valueOrNull ?? const <Friend>[];
  return {for (final friend in friends) friend.id: friend};
});

typedef ReviewAuthor = ({String name, String emoji});

ReviewAuthor resolveAuthor(
  Review review,
  Map<String, Friend> friends,
  String myName,
) {
  if (review.isMine) return (name: myName, emoji: '🍺');
  final friend = friends[review.authorId];
  return (name: friend?.name ?? 'Znajomy', emoji: friend?.emoji ?? '🙂');
}
