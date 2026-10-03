import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/check_in.dart';
import 'package:jak_wypije/data/models/review.dart';
import 'package:jak_wypije/features/friends/leagues.dart';
import 'package:jak_wypije/features/friends/trophies.dart';

CheckIn _checkIn(DateTime at, {int points = 10}) => CheckIn(
      barId: 'b',
      timestamp: at,
      points: points,
      method: CheckInMethod.demo,
    );

void main() {
  // Saturday, 3 October 2026 – the week started on Monday 28 September.
  final now = DateTime(2026, 10, 3, 21);

  test('league table sorts by XP and marks promotion/demotion zones', () {
    final table = LeagueTable([
      for (var i = 0; i < 9; i++)
        LeagueEntry(id: 'p$i', name: 'P$i', emoji: '🙂', weeklyXp: i * 10),
      const LeagueEntry(
        id: 'me',
        name: 'Ty',
        emoji: '🍺',
        weeklyXp: 45,
        isMe: true,
      ),
    ]);
    expect(table.entries.first.weeklyXp, 80);
    expect(table.myRank, 5);
    expect(table.zoneOf(0), LeagueZone.promotion);
    expect(table.zoneOf(2), LeagueZone.promotion);
    expect(table.zoneOf(3), LeagueZone.safe);
    expect(table.zoneOf(7), LeagueZone.demotion);
    expect(table.zoneOf(9), LeagueZone.demotion);
  });

  test('weekly XP resets on Monday and counts reviews', () {
    final xp = weeklyXpFrom(
      checkIns: [
        _checkIn(DateTime(2026, 9, 28, 20), points: 25),
        _checkIn(DateTime(2026, 10, 2, 22), points: 15),
        _checkIn(DateTime(2026, 9, 27, 23), points: 100), // previous week
      ],
      myReviews: [
        Review(
          id: 'r',
          barId: 'b',
          authorId: Review.myAuthorId,
          rating: 5,
          comment: '',
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
      now: now,
    );
    expect(xp, 25 + 15 + 5);
  });

  test('streak counts consecutive weeks, not days', () {
    final checkIns = [
      _checkIn(DateTime(2026, 10, 2)), // this week
      _checkIn(DateTime(2026, 9, 25)), // last week
      _checkIn(DateTime(2026, 9, 24)), // same week – counted once
      _checkIn(DateTime(2026, 9, 18)), // two weeks ago
      _checkIn(DateTime(2026, 9, 1)), // gap → not part of the streak
    ];
    expect(streakWeeksFrom(checkIns, now), 3);
    // Nothing yet this week: the streak from last week still counts.
    expect(streakWeeksFrom(checkIns.skip(1).toList(), now), 2);
    expect(streakWeeksFrom(const [], now), 0);
  });

  test('trophy tiers follow the thresholds', () {
    final explorer = allTrophies.firstWhere((t) => t.id == 'explorer');
    TrophyProgress at(int value) =>
        TrophyProgress(definition: explorer, value: value);

    expect(at(0).tier, TrophyTier.none);
    expect(at(3).tier, TrophyTier.bronze);
    expect(at(5).tier, TrophyTier.silver);
    expect(at(12).tier, TrophyTier.gold);
    expect(at(4).nextThreshold, 5);
    expect(at(4).progressToNext, closeTo(0.8, 1e-9));
    expect(at(12).nextThreshold, isNull);
    expect(at(12).progressToNext, 1);
  });
}
