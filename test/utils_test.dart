import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/core/utils/formatters.dart';
import 'package:jak_wypije/core/utils/geo.dart';
import 'package:jak_wypije/core/utils/time.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('evening time axis', () {
    test('night hours continue past 24:00', () {
      expect(parseEveningTime('19:30'), 19 * 60 + 30);
      expect(parseEveningTime('01:30'), 25 * 60 + 30);
      expect(eveningMinutes(DateTime(2026, 10, 4, 2, 15)), 26 * 60 + 15);
      expect(eveningMinutes(DateTime(2026, 10, 3, 22)), 22 * 60);
    });

    test('daytime city data shows the 21:00 forecast', () {
      final day = CityClock.of(DateTime(2026, 10, 3, 14));
      expect(day.isForecast, isTrue);
      expect(day.minutes, 21 * 60);
      final night = CityClock.of(DateTime(2026, 10, 4, 1));
      expect(night.isForecast, isFalse);
      expect(night.minutes, 25 * 60);
    });

    test('weeks start on Monday at midnight, also across DST', () {
      expect(weekStart(DateTime(2026, 10, 3, 21)), DateTime(2026, 9, 28));
      expect(weekStart(DateTime(2026, 9, 28)), DateTime(2026, 9, 28));
      // DST ends on 25 October 2026 in Poland.
      expect(weekStart(DateTime(2026, 10, 27, 12)), DateTime(2026, 10, 26));
      expect(weekStart(DateTime(2026, 10, 25, 23)), DateTime(2026, 10, 19));
    });
  });

  group('haversineMeters', () {
    test('is 0 for the same point', () {
      expect(haversineMeters(krakowCenter, krakowCenter), 0);
    });

    test('Rynek → Wawel is roughly 870 m', () {
      const wawel = LatLng(50.0540, 19.9354);
      expect(haversineMeters(krakowCenter, wawel), closeTo(867, 30));
    });

    test('walking time rounds up', () {
      expect(walkingMinutes(0), 0);
      expect(walkingMinutes(81), 2);
    });
  });

  group('formatters', () {
    test('formatPln uses Polish formatting', () {
      final text = formatPln(12.5);
      expect(text, contains('12,50'));
      expect(text, contains('zł'));
    });

    test('formatDistance', () {
      expect(formatDistance(450), '450 m');
      expect(formatDistance(1234), '1,2 km');
    });

    test('formatClock wraps after midnight', () {
      expect(formatClock(19 * 60 + 5), '19:05');
      expect(formatClock(25 * 60), '01:00');
    });

    test('formatDuration', () {
      expect(formatDuration(45), '45 min');
      expect(formatDuration(60), '1 h');
      expect(formatDuration(80), '1 h 20 min');
    });

    test('pluralize follows Polish rules', () {
      String bars(int n) => pluralize(n, 'bar', 'bary', 'barów');
      expect(bars(1), 'bar');
      expect(bars(3), 'bary');
      expect(bars(5), 'barów');
      expect(bars(12), 'barów');
      expect(bars(22), 'bary');
    });
  });
}
