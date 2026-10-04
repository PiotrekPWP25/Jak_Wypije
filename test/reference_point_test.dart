import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/core/utils/geo.dart';
import 'package:jak_wypije/features/bars/bars_providers.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('positions outside Kraków do not count as the user location', () {
    const kazimierz = LatLng(50.0518, 19.9449);
    const nowaHuta = LatLng(50.0712, 20.0373);
    const mountainView = LatLng(37.4220, -122.0841);

    expect(positionInCity(kazimierz), kazimierz);
    expect(positionInCity(nowaHuta), nowaHuta);
    expect(positionInCity(mountainView), isNull);
    expect(positionInCity(null), isNull);
    expect(positionInCity(krakowCenter), krakowCenter);
  });
}
