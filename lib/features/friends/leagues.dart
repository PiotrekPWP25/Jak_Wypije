import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time.dart';
import '../../data/models/check_in.dart';
import '../../data/models/friend.dart';
import '../../data/models/review.dart';
import '../../data/repositories/social_repository.dart';
import '../checkin/check_in_controller.dart';
import '../gamification/challenges.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/scoring.dart';
import '../profile/profile_providers.dart';
import 'reviews_controller.dart';

/// Weekly leagues, Duolingo-style: top 3 go up, bottom 3 go down.
enum League { bronze, silver, gold, sapphire, ruby, diamond }

extension LeagueX on League {
  String get label => switch (this) {
        League.bronze => 'Liga Brązowa',
        League.silver => 'Liga Srebrna',
        League.gold => 'Liga Złota',
        League.sapphire => 'Liga Szafirowa',
        League.ruby => 'Liga Rubinowa',
        League.diamond => 'Liga Diamentowa',
      };

  Color get color => switch (this) {
        League.bronze => AppColors.bronze,
        League.silver => AppColors.silver,
        League.gold => AppColors.gold,
        League.sapphire => const Color(0xFF3F7FE0),
        League.ruby => const Color(0xFFD7263D),
        League.diamond => const Color(0xFF7FD8E8),
      };
}

League leagueById(String id) =>
    League.values.where((league) => league.name == id).firstOrNull ??
    League.bronze;

/// The user's current league (mock until there is a backend).
const League myLeague = League.silver;

enum LeagueZone { promotion, safe, demotion }

class LeagueEntry {
  const LeagueEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.weeklyXp,
    this.isMe = false,
    this.isFriend = false,
  });

  final String id;
  final String name;
  final String emoji;
  final int weeklyXp;
  final bool isMe;
  final bool isFriend;
}

class LeagueTable {
  LeagueTable(List<LeagueEntry> entries)
      : entries = List<LeagueEntry>.unmodifiable(
          [...entries]..sort((a, b) {
              final byXp = b.weeklyXp.compareTo(a.weeklyXp);
              return byXp != 0 ? byXp : a.name.compareTo(b.name);
            }),
        );

  static const int promotionSlots = 3;
  static const int demotionSlots = 3;

  final List<LeagueEntry> entries;

  LeagueZone zoneOf(int index) {
    if (index < promotionSlots) return LeagueZone.promotion;
    if (index >= entries.length - demotionSlots) return LeagueZone.demotion;
    return LeagueZone.safe;
  }

  /// 1-based rank of the user, or `null` when not in the table.
  int? get myRank {
    final index = entries.indexWhere((entry) => entry.isMe);
    return index < 0 ? null : index + 1;
  }
}

/// XP earned since Monday: check-ins plus reviews written this week.
int weeklyXpFrom({
  required List<CheckIn> checkIns,
  required List<Review> myReviews,
  required DateTime now,
}) {
  final start = weekStart(now);
  final fromCheckIns = checkIns
      .where((checkIn) => !checkIn.timestamp.isBefore(start))
      .fold<int>(0, (sum, checkIn) => sum + checkIn.points);
  final fromReviews =
      myReviews.where((review) => !review.createdAt.isBefore(start)).length *
          MyReviewsNotifier.pointsPerReview;
  return fromCheckIns + fromReviews;
}

/// Consecutive weeks with at least one check-in. Counted in weeks (not days)
/// on purpose – the app must not reward drinking every day.
int streakWeeksFrom(List<CheckIn> checkIns, DateTime now) {
  final weeks = checkIns.map((checkIn) => weekStart(checkIn.timestamp)).toSet();
  var week = weekStart(now);
  if (!weeks.contains(week)) {
    week = DateTime(week.year, week.month, week.day - 7);
  }
  var streak = 0;
  while (weeks.contains(week)) {
    streak++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  return streak;
}

Duration untilWeekEnds(DateTime now) =>
    weekStart(now).add(const Duration(days: 7)).difference(now);

/// Weekly XP: check-ins and reviews, plus walking and finished challenges –
/// the league rewards exploring the city, not drinking.
final myWeeklyXpProvider = Provider<int>((ref) {
  return weeklyXpFrom(
        checkIns: ref.watch(checkInsProvider),
        myReviews: ref.watch(myReviewsProvider),
        now: DateTime.now(),
      ) +
      walkingXp(ref.watch(walkedMetersWeekProvider)) +
      challengeXp(ref.watch(weeklyChallengesProvider));
});

final myStreakWeeksProvider = Provider<int>(
  (ref) => streakWeeksFrom(ref.watch(checkInsProvider), DateTime.now()),
);

final leagueTableProvider = Provider<LeagueTable>((ref) {
  final people = ref.watch(friendsProvider).valueOrNull ?? const <Friend>[];
  return LeagueTable([
    for (final person in people)
      if (person.leagueId == myLeague.name)
        LeagueEntry(
          id: person.id,
          name: person.name,
          emoji: person.emoji,
          weeklyXp: person.weeklyXp,
          isFriend: person.isFriend,
        ),
    LeagueEntry(
      id: 'me',
      name: ref.watch(userNameProvider),
      emoji: '🍺',
      weeklyXp: ref.watch(myWeeklyXpProvider),
      isMe: true,
    ),
  ]);
});
