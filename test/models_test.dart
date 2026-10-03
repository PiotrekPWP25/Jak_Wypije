import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/bar.dart';
import 'package:jak_wypije/data/models/city_zone.dart';
import 'package:jak_wypije/data/models/evening_plan.dart';
import 'package:jak_wypije/data/models/price_range.dart';
import 'package:jak_wypije/features/barobranie/plan_calculator.dart';
import 'package:jak_wypije/features/checkin/check_in_controller.dart';

import 'fixtures.dart';

void main() {
  test('Bar survives a JSON round trip, incl. hours past midnight', () {
    final bar = testBar(
      'b1',
      extra: {
        'shot': {'min': 8, 'max': 12},
        'food': {'min': 30, 'max': 40},
        'kitchenUntil': '23:30',
        'acceptsCards': false,
        'accessibility': {'stepFree': true, 'accessibleToilet': true},
      },
    );
    final copy = Bar.fromJson(bar.toJson());
    expect(copy.location, bar.location);
    expect(copy.closesAt, 26 * 60);
    expect(copy.openHours, '16:00–02:00');
    expect(copy.shot?.label, '8–12 zł');
    expect(copy.food?.label, '30–40 zł');
    expect(copy.drink, isNull);
    expect(copy.hasLateKitchen, isTrue);
    expect(copy.acceptsCards, isFalse);
    expect(copy.accessibility.isBarrierFree, isTrue);
    expect(copy.qrPayload, 'jakwypije:bar:b1');
  });

  test('Bar.isOpenAt works on the evening axis', () {
    final bar = testBar('b1');
    expect(bar.isOpenAt(15 * 60), isFalse);
    expect(bar.isOpenAt(23 * 60), isTrue);
    expect(bar.isOpenAt(25 * 60), isTrue);
    expect(bar.isOpenAt(26 * 60), isFalse);
  });

  test('PriceRange label, overlap and arithmetic', () {
    const range = PriceRange(min: 12, max: 16);
    expect(range.label, '12–16 zł');
    expect(const PriceRange(min: 9, max: 9).label, '9 zł');
    expect(range.overlaps(15, 20), isTrue);
    expect(range.overlaps(17, 20), isFalse);
    final total = range * 2 + const PriceRange(min: 10, max: 10);
    expect(total.min, 34);
    expect(total.max, 42);
  });

  test('CityZone crowd profile is clamped to its hours', () {
    final zone = CityZone.fromJson({
      'id': 'z',
      'name': 'Z',
      'lat': 50,
      'lng': 19,
      'radiusMeters': 100,
      'crowdByHour': [10, 20, 30, 40, 50, 60, 70, 80, 90],
    });
    expect(zone.crowdAt(18 * 60), 10);
    expect(zone.crowdAt(22 * 60 + 30), 50);
    expect(zone.crowdAt(12 * 60), 10);
    expect(zone.crowdAt(30 * 60), 90);
    expect(zone.levelAt(25 * 60), CrowdLevel.high);
  });

  test('parseBarQr', () {
    expect(parseBarQr('jakwypije:bar:b07'), 'b07');
    expect(parseBarQr('https://example.com'), isNull);
    expect(parseBarQr('jakwypije:bar:'), isNull);
    expect(parseBarQr(null), isNull);
  });

  test('isSameEvening treats the night as one evening', () {
    expect(
      isSameEvening(DateTime(2026, 10, 3, 22), DateTime(2026, 10, 4, 2)),
      isTrue,
    );
    expect(
      isSameEvening(DateTime(2026, 10, 3, 22), DateTime(2026, 10, 4, 20)),
      isFalse,
    );
  });

  group('plan calculator', () {
    final a = testBar('a', lat: 50.0500);
    final b = testBar(
      'b',
      lat: 50.0600,
      extra: {
        'beer': {'min': 12, 'max': 14},
      },
    );
    final c = testBar('c', lat: 50.0510);

    test('builds a timeline with walking legs and a budget range', () {
      const plan = EveningPlan(
        barIds: ['a', 'b'],
        startMinutes: 19 * 60,
        minutesPerStop: 60,
        drinksPerStop: 2,
      );
      final summary = calculatePlan(plan, [a, b]);
      expect(summary.stops, hasLength(2));
      expect(summary.stops.first.arrivalMinutes, 19 * 60);
      expect(summary.stops.first.walkMeters, 0);
      expect(summary.totalWalkMeters, closeTo(1112, 5));
      expect(summary.stops[1].arrivalMinutes, 20 * 60 + 14);
      expect(summary.totalCost.min, 44);
      expect(summary.totalCost.max, 52);
      expect(summary.warningCount, 0);
    });

    test('warns about closed bars, crowds and quiet hours', () {
      final late = testBar('late', extra: {'opensAt': '21:00'});
      final busy = testBar('busy', zoneId: 'busy');
      const plan = EveningPlan(
        barIds: ['late', 'busy'],
        startMinutes: 19 * 60,
        minutesPerStop: 120,
        drinksPerStop: 1,
      );
      final summary = calculatePlan(
        plan,
        [late, busy],
        zones: {'busy': testZone('busy', crowd: 90, quietZone: true)},
      );
      final types = [
        for (final stop in summary.stops)
          for (final warning in stop.warnings) warning.type,
      ];
      expect(types, contains(PlanWarningType.closed));
      expect(types, contains(PlanWarningType.crowded));
      expect(types, contains(PlanWarningType.quietZone));
    });

    test('warns when the bar closes before you leave', () {
      final early = testBar('early', extra: {'closesAt': '20:00'});
      const plan = EveningPlan(
        barIds: ['early'],
        startMinutes: 19 * 60,
        minutesPerStop: 90,
        drinksPerStop: 1,
      );
      final warning = calculatePlan(plan, [early]).stops.single.warnings.single;
      expect(warning.type, PlanWarningType.closesEarly);
    });

    test('optimizeRoute keeps the start and visits nearest bars first', () {
      expect(optimizeRoute([a, b, c]), ['a', 'c', 'b']);
    });

    test('calmerAlternative suggests the nearest calm, open bar', () {
      final crowded = testBar('crowded', zoneId: 'busy');
      final calmNear = testBar('near', lat: 50.051, zoneId: 'calm');
      final calmFar = testBar('far', lat: 50.06, zoneId: 'calm');
      final zones = {
        'busy': testZone('busy', crowd: 95),
        'calm': testZone('calm', crowd: 10),
      };
      final alternative = calmerAlternative(
        crowded,
        [crowded, calmFar, calmNear],
        zones,
        atMinutes: 22 * 60,
        excludeIds: {'crowded'},
      );
      expect(alternative?.id, 'near');
    });
  });
}
