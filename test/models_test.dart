import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/bar.dart';
import 'package:jak_wypije/data/models/evening_plan.dart';
import 'package:jak_wypije/data/models/fundraiser.dart';
import 'package:jak_wypije/features/checkin/check_in_controller.dart';
import 'package:jak_wypije/features/planner/plan_calculator.dart';

Bar _bar(String id, double lat, double lng, {double price = 10}) => Bar.fromJson({
      'id': id,
      'name': 'Bar $id',
      'address': 'ul. Testowa 1',
      'district': 'Kazimierz',
      'lat': lat,
      'lng': lng,
      'beerPrice': price,
      'tags': ['test'],
    });

void main() {
  test('Bar survives a JSON round trip', () {
    final bar = _bar('b1', 50.05, 19.94);
    final copy = Bar.fromJson(bar.toJson());
    expect(copy.id, bar.id);
    expect(copy.location, bar.location);
    expect(copy.tags, ['test']);
    expect(copy.qrPayload, 'jakwypije:bar:b1');
  });

  test('Fundraiser applies local contributions', () {
    final fundraiser = Fundraiser.fromJson({
      'id': 'f1',
      'barId': 'b1',
      'title': 'Test',
      'goal': 1000,
      'raised': 900,
      'backers': 10,
      'deadline': '2026-12-31T23:59:00',
    });
    expect(fundraiser.isSaved, isFalse);
    expect(fundraiser.progress, closeTo(0.9, 1e-9));

    final supported = fundraiser.withContribution(100);
    expect(supported.isSaved, isTrue);
    expect(supported.backers, 11);
    expect(supported.myContribution, 100);
    expect(supported.progress, 1);
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
    final a = _bar('a', 50.0500, 19.9400, price: 10);
    final b = _bar('b', 50.0600, 19.9400, price: 12);
    final c = _bar('c', 50.0510, 19.9400, price: 14);

    test('builds a timeline with walking legs and budget', () {
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
      expect(summary.totalCost, 44);
    });

    test('optimizeRoute keeps the start and visits nearest bars first', () {
      expect(optimizeRoute([a, b, c]), ['a', 'c', 'b']);
    });
  });
}
