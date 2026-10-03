import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/bar.dart';
import '../../data/models/fundraiser.dart';
import '../../data/repositories/bar_repository.dart';
import '../barobranie/barobranie_providers.dart';
import '../checkin/check_in_controller.dart';
import '../friends/reviews_controller.dart';
import '../planner/planner_controller.dart';
import 'achievements.dart';

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
    required this.reviews,
    required this.planStops,
    required this.supportedFundraisers,
    required this.savedFundraisersSupported,
    required this.totalContributed,
    required this.points,
  });

  final int checkIns;
  final int uniqueBars;
  final int districts;
  final int hiddenGems;
  final int reviews;
  final int planStops;
  final int supportedFundraisers;
  final int savedFundraisersSupported;
  final double totalContributed;
  final int points;
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final checkIns = ref.watch(checkInsProvider);
  final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
  final contributions = ref.watch(contributionsProvider);
  final fundraisers =
      ref.watch(fundraisersProvider).valueOrNull ?? const <Fundraiser>[];
  final myReviews = ref.watch(myReviewsProvider);
  final plan = ref.watch(plannerProvider);

  final barsById = {for (final bar in bars) bar.id: bar};
  final visitedIds = checkIns.map((checkIn) => checkIn.barId).toSet();
  final visitedBars = visitedIds.map((id) => barsById[id]).nonNulls.toList();
  final totalContributed =
      contributions.values.fold<double>(0.0, (sum, value) => sum + value);
  final checkInPoints =
      checkIns.fold<int>(0, (sum, checkIn) => sum + checkIn.points);
  final points = checkInPoints +
      myReviews.length * MyReviewsNotifier.pointsPerReview +
      (totalContributed / 2).floor();

  return ProfileStats(
    checkIns: checkIns.length,
    uniqueBars: visitedIds.length,
    districts: visitedBars.map((bar) => bar.district).toSet().length,
    hiddenGems: visitedBars.where((bar) => bar.isHiddenGem).length,
    reviews: myReviews.length,
    planStops: plan.barIds.length,
    supportedFundraisers: contributions.values.where((v) => v > 0).length,
    savedFundraisersSupported: fundraisers
        .where((fundraiser) => fundraiser.isSaved && fundraiser.myContribution > 0)
        .length,
    totalContributed: totalContributed,
    points: points,
  );
});

final achievementsProvider = Provider<List<AchievementProgress>>((ref) {
  final stats = ref.watch(profileStatsProvider);
  return [
    for (final achievement in allAchievements)
      AchievementProgress(
        achievement: achievement,
        unlocked: isAchievementUnlocked(achievement.id, stats),
      ),
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
