import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/core/utils/maps_link.dart';
import 'package:jak_wypije/features/barobranie/plan_calculator.dart';
import 'package:jak_wypije/features/barobranie/route_export.dart';
import 'package:jak_wypije/data/models/evening_plan.dart';
import 'package:latlong2/latlong.dart';

import 'fixtures.dart';

void main() {
  test('builds a walking directions link with waypoints', () {
    final urls = googleMapsDirectionsUrls(const [
      LatLng(50.0617, 19.9373),
      LatLng(50.0515, 19.9455),
      LatLng(50.0447, 19.9536),
    ]);
    expect(urls, hasLength(1));
    final url = urls.single;
    expect(url.host, 'www.google.com');
    expect(url.path, '/maps/dir/');
    expect(url.queryParameters['api'], '1');
    expect(url.queryParameters['travelmode'], 'walking');
    expect(url.queryParameters['origin'], '50.061700,19.937300');
    expect(url.queryParameters['destination'], '50.044700,19.953600');
    expect(url.queryParameters['waypoints'], '50.051500,19.945500');
  });

  test('splits long routes into legs that share endpoints', () {
    final points = [
      for (var i = 0; i < 15; i++) LatLng(50 + i / 1000, 19.9),
    ];
    final urls = googleMapsDirectionsUrls(points);
    expect(urls, hasLength(2));
    expect(urls[0].queryParameters['waypoints']!.split('|'), hasLength(9));
    expect(
      urls[1].queryParameters['origin'],
      urls[0].queryParameters['destination'],
    );
    expect(urls[1].queryParameters['destination'], '50.014000,19.900000');
  });

  test('fewer than two points give no link', () {
    expect(googleMapsDirectionsUrls(const [LatLng(50, 19)]), isEmpty);
  });

  test('share text lists stops with times and the Maps link', () {
    const plan = EveningPlan(
      stopIds: ['l1', 'b1'],
      startMinutes: 18 * 60,
      minutesPerStop: 60,
      drinksPerStop: 1,
    );
    final summary = calculatePlan(plan, [
      testLandmark('l1', lat: 50.050),
      testBar('b1', lat: 50.052),
    ]);
    final text = planShareText(summary);
    expect(text, contains('1. 18:00'));
    expect(text, contains('Atrakcja l1'));
    expect(text, contains('2. 18:3'));
    expect(text, contains('https://www.google.com/maps/dir/'));
  });
}
