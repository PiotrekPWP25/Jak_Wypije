import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/evening_plan.dart';
import 'package:jak_wypije/data/models/place.dart';
import 'package:jak_wypije/features/gamification/challenges.dart';
import 'package:jak_wypije/features/gamification/scoring.dart';

import 'fixtures.dart';

void main() {
  final evening = DateTime(2026, 10, 3, 19);
  final bar1 = testBar('b1', lat: 50.050, extra: {'districtNo': 1});
  final bar2 = testBar('b2', lat: 50.055, extra: {'districtNo': 1});
  final bar3 = testBar('b3', lat: 50.060, extra: {'districtNo': 13});
  final sight = testLandmark('l1', lat: 50.052, districtNo: 1);
  final places = <String, Place>{
    for (final p in [bar1, bar2, bar3, sight]) p.id: p,
  };

  test('only two bars per evening are scored, landmarks always', () {
    final history = [
      testCheckIn(bar1, evening),
      testCheckIn(bar2, evening.add(const Duration(hours: 1))),
    ];
    final thirdBar = scoreCheckIn(
      place: bar3,
      history: history,
      at: evening.add(const Duration(hours: 2)),
      placesById: places,
    );
    expect(thirdBar.points, 0, reason: 'no district bonus when capped');

    final landmark = scoreCheckIn(
      place: sight,
      history: history,
      at: evening.add(const Duration(hours: 2)),
      placesById: places,
    );
    expect(landmark.points, Scoring.landmarkBase + Scoring.landmarkFirstVisit);
  });

  test('bar cap resets the next evening', () {
    final history = [
      testCheckIn(bar1, evening),
      testCheckIn(bar2, evening.add(const Duration(hours: 1))),
    ];
    final nextDay = scoreCheckIn(
      place: bar3,
      history: history,
      at: evening.add(const Duration(days: 1)),
      placesById: places,
    );
    expect(nextDay.points, Scoring.barBase + Scoring.newDistrictBonus);
  });

  test('finishing a route with a landmark gives the route bonus once', () {
    const plan = EveningPlan(
      stopIds: ['l1', 'b1'],
      startMinutes: 18 * 60,
      minutesPerStop: 60,
      drinksPerStop: 1,
    );
    final history = [testCheckIn(sight, evening)];
    final result = scoreCheckIn(
      place: bar1,
      history: history,
      at: evening.add(const Duration(hours: 1)),
      placesById: places,
      plan: plan,
    );
    expect(result.completedRoute, isTrue);
    expect(result.bonuses, contains('Trasa ukończona +${Scoring.routeBonus}'));

    const barsOnly = EveningPlan(
      stopIds: ['b2', 'b1'],
      startMinutes: 18 * 60,
      minutesPerStop: 60,
      drinksPerStop: 1,
    );
    final crawl = scoreCheckIn(
      place: bar1,
      history: [testCheckIn(bar2, evening)],
      at: evening.add(const Duration(hours: 1)),
      placesById: places,
      plan: barsOnly,
    );
    expect(crawl.completedRoute, isFalse, reason: 'needs a landmark');
  });

  test('walking distance is summed per evening and capped', () {
    final meters = walkedMeters(
      [
        testCheckIn(bar1, evening),
        testCheckIn(bar2, evening.add(const Duration(hours: 1))),
        // Next evening starts a fresh walk.
        testCheckIn(bar3, evening.add(const Duration(days: 1))),
      ],
      places,
    );
    expect(meters, closeTo(556, 5));
    expect(walkingXp(2500), 25);
  });

  test('passport stamps come from check-in districts', () {
    expect(
      stampedDistricts(
          [testCheckIn(bar1, evening), testCheckIn(bar3, evening)], places),
      {1, 13},
    );
  });

  group('weekly challenges', () {
    test('three different challenges rotate every week', () {
      final week1 = challengesForWeek(DateTime(2026, 10, 3));
      final week2 = challengesForWeek(DateTime(2026, 10, 10));
      expect(week1.map((c) => c.id).toSet(), hasLength(3));
      expect(week1.first.id, isNot(week2.first.id));
      expect(challengesForWeek(DateTime(2026, 9, 28)).first.id, week1.first.id);
    });

    test('progress and XP from this week\'s check-ins', () {
      final progress = challengeProgress(
        challenges: allChallenges,
        weekCheckIns: [
          testCheckIn(bar3, evening),
          testCheckIn(testBar('b4', extra: {'districtNo': 13}), evening),
          testCheckIn(sight, evening),
        ],
        placesById: {
          ...places,
          'b4': testBar('b4', extra: {'districtNo': 13}),
        },
        walkedMeters: 5200,
      );
      final byId = {for (final p in progress) p.challenge.id: p};
      expect(byId['podgorze']!.completed, isTrue);
      expect(byId['history']!.value, 1);
      expect(byId['walker']!.completed, isTrue);
      expect(challengeXp(progress), 40 + 50);
    });
  });
}
