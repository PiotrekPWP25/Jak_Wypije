import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Main Market Square – fallback when the user's location is unknown.
const LatLng krakowCenter = LatLng(50.0617, 19.9373);

/// Average walking speed (~4.8 km/h).
const double walkingSpeedMetersPerMinute = 80;

const double _earthRadiusMeters = 6371000;

/// Great-circle distance between two points in meters (haversine formula).
double haversineMeters(LatLng a, LatLng b) {
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLng = _toRadians(b.longitude - a.longitude);
  final sinLat = math.sin(dLat / 2);
  final sinLng = math.sin(dLng / 2);
  final h = sinLat * sinLat +
      math.cos(_toRadians(a.latitude)) *
          math.cos(_toRadians(b.latitude)) *
          sinLng *
          sinLng;
  return 2 * _earthRadiusMeters * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Walking time in whole minutes (rounded up).
int walkingMinutes(double meters) =>
    (meters / walkingSpeedMetersPerMinute).ceil();

double _toRadians(double degrees) => degrees * math.pi / 180;
