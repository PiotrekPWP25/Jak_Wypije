import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/transit_stop.dart';
import 'package:jak_wypije/features/barobranie/safe_return.dart';
import 'package:latlong2/latlong.dart';

TransitStop _stop(
  String id,
  double lat, {
  required List<Map<String, dynamic>> lines,
}) {
  return TransitStop.fromJson({
    'id': id,
    'name': 'Przystanek $id',
    'lat': lat,
    'lng': 19.94,
    'lines': lines,
  });
}

const _night = {
  'number': '62',
  'headsign': 'Os. Piastów',
  'night': true,
  'from': '23:30',
  'to': '04:30',
  'every': 30,
};

const _day = {
  'number': '8',
  'headsign': 'Bronowice',
  'night': false,
  'from': '12:00',
  'to': '23:00',
  'every': 10,
};

void main() {
  test('night line departures continue past midnight', () {
    final line = TransitLine.fromJson(_night);
    expect(line.firstDeparture, 23 * 60 + 30);
    expect(line.lastDeparture, 28 * 60 + 30);
    expect(
      line.departuresFrom(24 * 60 + 10),
      [24 * 60 + 30, 25 * 60, 25 * 60 + 30],
    );
    expect(line.departuresFrom(29 * 60), isEmpty);
  });

  test('picks the nearest stop that still has service', () {
    const from = LatLng(50.0500, 19.94);
    final dayOnlyNear = _stop('near', 50.0502, lines: [_day]);
    final nightFurther = _stop('far', 50.0520, lines: [_night]);

    final option = findSafeReturn(
      from: from,
      leaveAt: 24 * 60 + 15,
      stops: [nightFurther, dayOnlyNear],
    );

    expect(option, isNotNull);
    expect(option!.stop.id, 'far');
    expect(option.hasNightService, isTrue);
    expect(option.departures.first.minutes, 24 * 60 + 30);
    expect(option.walkMinutes, greaterThan(0));
  });

  test('prefers the nearest stop in the evening', () {
    const from = LatLng(50.0500, 19.94);
    final option = findSafeReturn(
      from: from,
      leaveAt: 21 * 60,
      stops: [
        _stop('far', 50.0600, lines: [_day]),
        _stop('near', 50.0503, lines: [_day]),
      ],
    );
    expect(option?.stop.id, 'near');
    expect(option?.departures, hasLength(3));
  });

  test('returns null when nothing runs', () {
    expect(
      findSafeReturn(
        from: const LatLng(50.05, 19.94),
        leaveAt: 30 * 60,
        stops: [
          _stop('x', 50.05, lines: [_day])
        ],
      ),
      isNull,
    );
  });
}
