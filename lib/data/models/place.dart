import 'package:latlong2/latlong.dart';

enum PlaceType { bar, landmark }

/// Anything that can be a stop on a route: a bar or a city landmark.
abstract interface class Place {
  String get id;
  String get name;
  String get emoji;

  /// Neighbourhood shown in the UI (e.g. "Kazimierz").
  String get district;

  /// Official Kraków district number (1–18) used by the passport.
  int get districtNo;

  /// Nightlife zone for crowd levels; empty when outside any zone.
  String get zoneId;
  LatLng get location;
  PlaceType get type;
  bool get isNew;

  /// [minutes] on the evening axis.
  bool isOpenAt(int minutes);
}
