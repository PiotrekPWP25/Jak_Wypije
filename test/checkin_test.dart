import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/local/local_storage.dart';
import 'package:jak_wypije/data/models/check_in.dart';
import 'package:jak_wypije/features/checkin/check_in_controller.dart';
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

  test('hidden gem outside the crowd gets all bonuses once per evening', () {
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
      CheckInsNotifier.basePoints +
          CheckInsNotifier.firstVisitBonus +
          CheckInsNotifier.hiddenGemBonus +
          CheckInsNotifier.offPeakBonus,
    );
    expect(container.read(checkInsProvider).single.offPeak, isTrue);

    final again = notifier.checkIn(
      bar,
      method: CheckInMethod.demo,
      now: at.add(const Duration(hours: 3)),
    );
    expect(again.success, isFalse);
  });

  test('crowded zone gives no off-peak bonus', () {
    final notifier = container.read(checkInsProvider.notifier);
    final result = notifier.checkIn(
      testBar('busy'),
      method: CheckInMethod.qr,
      zone: testZone('busy', crowd: 90),
      now: DateTime(2026, 10, 3, 22),
    );
    expect(
      result.points,
      CheckInsNotifier.basePoints + CheckInsNotifier.firstVisitBonus,
    );
    expect(container.read(checkInsProvider).single.offPeak, isFalse);
  });
}
