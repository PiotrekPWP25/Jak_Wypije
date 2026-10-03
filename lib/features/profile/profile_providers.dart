import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/bar.dart';
import '../../data/repositories/bar_repository.dart';
import '../barobranie/planner_controller.dart';
import '../barobranie/safe_return.dart';
import '../checkin/check_in_controller.dart';
import '../friends/reviews_controller.dart';
import '../friends/trophies.dart';

class UserNameNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(localStorageProvider).loadUserName();

  Future<void> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = trimmed;
    await ref.read(localStorageProvider).saveUserName(trimmed);
  }
}

final userNameProvider = NotifierProvider<UserNameNotifier, String>(
  UserNameNotifier.new,
);

class ProfileStats {
  const ProfileStats({
    required this.checkIns,
    required this.uniqueBars,
    required this.districts,
    required this.hiddenGems,
    required this.offPeakCheckIns,
    required this.barrierFreeBars,
    required this.reviews,
    required this.planStops,
    required this.safeReturns,
    required this.points,
  });

  final int checkIns;
  final int uniqueBars;
  final int districts;
  final int hiddenGems;
  final int offPeakCheckIns;
  final int barrierFreeBars;
  final int reviews;
  final int planStops;
  final int safeReturns;
  final int points;
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final checkIns = ref.watch(checkInsProvider);
  final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
  final myReviews = ref.watch(myReviewsProvider);

  final barsById = {for (final bar in bars) bar.id: bar};
  final visitedIds = checkIns.map((checkIn) => checkIn.barId).toSet();
  final visitedBars = visitedIds.map((id) => barsById[id]).nonNulls.toList();
  final checkInPoints =
      checkIns.fold<int>(0, (sum, checkIn) => sum + checkIn.points);

  return ProfileStats(
    checkIns: checkIns.length,
    uniqueBars: visitedIds.length,
    districts: visitedBars.map((bar) => bar.district).toSet().length,
    hiddenGems: visitedBars.where((bar) => bar.isHiddenGem).length,
    offPeakCheckIns: checkIns.where((checkIn) => checkIn.offPeak).length,
    barrierFreeBars:
        visitedBars.where((bar) => bar.accessibility.isBarrierFree).length,
    reviews: myReviews.length,
    planStops: ref.watch(plannerProvider).barIds.length,
    safeReturns: ref.watch(safeReturnsProvider),
    points:
        checkInPoints + myReviews.length * MyReviewsNotifier.pointsPerReview,
  );
});

final trophiesProvider = Provider<List<TrophyProgress>>((ref) {
  final stats = ref.watch(profileStatsProvider);
  return [
    for (final trophy in allTrophies)
      TrophyProgress(definition: trophy, value: trophy.metric(stats)),
  ];
});

class Level {
  const Level({
    required this.number,
    required this.title,
    required this.minPoints,
    this.nextPoints,
  });

  final int number;
  final String title;
  final int minPoints;

  /// `null` for the highest level.
  final int? nextPoints;

  double progress(int points) {
    final next = nextPoints;
    if (next == null) return 1.0;
    return ((points - minPoints) / (next - minPoints)).clamp(0.0, 1.0);
  }
}

const List<(int, String)> _levelThresholds = [
  (0, 'Nowicjusz'),
  (100, 'Bywalec'),
  (250, 'Odkrywca'),
  (500, 'Kustosz Barów'),
  (900, 'Legenda Kazimierza'),
];

Level levelFor(int points) {
  var index = 0;
  for (var i = 0; i < _levelThresholds.length; i++) {
    if (points >= _levelThresholds[i].$1) index = i;
  }
  final (minPoints, title) = _levelThresholds[index];
  final isLast = index == _levelThresholds.length - 1;
  return Level(
    number: index + 1,
    title: title,
    minPoints: minPoints,
    nextPoints: isLast ? null : _levelThresholds[index + 1].$1,
  );
}
