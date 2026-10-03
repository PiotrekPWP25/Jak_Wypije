import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/core/utils/formatters.dart';
import 'package:jak_wypije/core/utils/geo.dart';
import 'package:latlong2/latlong.dart';

void main() {
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
