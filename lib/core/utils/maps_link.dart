import 'package:latlong2/latlong.dart';

/// Google Maps allows up to 9 waypoints between origin and destination.
const int maxGoogleMapsWaypoints = 9;

String _coords(LatLng point) =>
    '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';

/// Walking directions through [points] as Google Maps URLs (Maps URLs API).
///
/// Long routes are split into legs that share their end/start point, so every
/// link stays within the waypoint limit. Returns an empty list for fewer than
/// two points.
List<Uri> googleMapsDirectionsUrls(List<LatLng> points) {
  if (points.length < 2) return const [];
  const perLink = maxGoogleMapsWaypoints + 2;
  final urls = <Uri>[];
  var start = 0;
  while (start < points.length - 1) {
    final end = (start + perLink).clamp(0, points.length);
    final leg = points.sublist(start, end);
    urls.add(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'origin': _coords(leg.first),
        'destination': _coords(leg.last),
        if (leg.length > 2)
          'waypoints': leg.sublist(1, leg.length - 1).map(_coords).join('|'),
        'travelmode': 'walking',
      }),
    );
    start = end - 1;
  }
  return urls;
}
