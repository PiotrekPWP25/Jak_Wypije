import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/local/local_storage.dart';
import 'package:jak_wypije/data/models/check_in.dart';
import 'package:jak_wypije/features/checkin/check_in_controller.dart';
import 'package:jak_wypije/features/gamification/scoring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  test('hidden gem outside the crowd: once per evening, persisted', () {
    final notifier = container.read(checkInsProvider.notifier);
    final bar = testBar('gem', extra: {'isHiddenGem': true});
    final at = DateTime(2026, 10, 3, 21);

    final first = notifier.checkIn(
      bar,
      method: CheckInMethod.demo,
      zone: testZone('calm', crowd: 10),
      now: at,
    );
    expect(first.success, isTrue);
    expect(
      first.points,
      Scoring.barBase + Scoring.hiddenGemBonus + Scoring.offPeakBonus,
    );
    final stored = container.read(checkInsProvider).single;
    expect(stored.offPeak, isTrue);
    expect(stored.placeId, 'gem');

    final again = notifier.checkIn(
      bar,
      method: CheckInMethod.demo,
      now: at.add(const Duration(hours: 3)),
    );
    expect(again.success, isFalse);
  });

  test('third bar of the evening earns no points', () {
    final notifier = container.read(checkInsProvider.notifier);
    final at = DateTime(2026, 10, 3, 20);
    for (final id in ['a', 'b']) {
      expect(
        notifier.checkIn(testBar(id), method: CheckInMethod.qr, now: at).points,
        Scoring.barBase,
      );
    }
    final third = notifier.checkIn(
      testBar('c'),
      method: CheckInMethod.qr,
      now: at.add(const Duration(hours: 2)),
    );
    expect(third.success, isTrue);
    expect(third.points, 0);
    expect(third.bonuses.single, contains('2 bary na wieczór'));
  });

  test('landmarks always score and stamp a new district', () {
    final notifier = container.read(checkInsProvider.notifier);
    final result = notifier.checkIn(
      testLandmark('l1', districtNo: 13),
      method: CheckInMethod.gps,
      now: DateTime(2026, 10, 3, 18),
    );
    expect(
      result.points,
      Scoring.landmarkBase +
          Scoring.landmarkFirstVisit +
          Scoring.newDistrictBonus,
    );
    expect(container.read(checkInsProvider).single.districtNo, 13);
  });
}
