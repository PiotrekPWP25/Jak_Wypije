import 'package:latlong2/latlong.dart';

/// One of the 18 official districts of Kraków (passport stamps).
class CityDistrict {
  const CityDistrict({
    required this.no,
    required this.name,
    required this.center,
  });

  factory CityDistrict.fromJson(Map<String, dynamic> json) {
    return CityDistrict(
      no: (json['no'] as num).toInt(),
      name: json['name'] as String,
      center: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
    );
  }

  final int no;
  final String name;
  final LatLng center;

  static const List<String> _roman = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', //
    'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII',
  ];

  String get roman => no >= 1 && no <= _roman.length ? _roman[no - 1] : '$no';

  Map<String, dynamic> toJson() => {
        'no': no,
        'name': name,
        'lat': center.latitude,
        'lng': center.longitude,
      };
}
