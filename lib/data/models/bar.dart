import 'package:latlong2/latlong.dart';

/// A bar in Kraków. All names in the mock data are fictional.
class Bar {
  const Bar({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.location,
    required this.description,
    required this.tags,
    required this.priceLevel,
    required this.beerPrice,
    required this.isHiddenGem,
    required this.openHours,
    required this.emoji,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      description: json['description'] as String? ?? '',
      tags: List<String>.unmodifiable(
        (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      ),
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 2,
      beerPrice: (json['beerPrice'] as num).toDouble(),
      isHiddenGem: json['isHiddenGem'] as bool? ?? false,
      openHours: json['openHours'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🍺',
    );
  }

  /// Payload encoded in the QR sticker placed in every partner bar.
  static const String qrPrefix = 'jakwypije:bar:';

  final String id;
  final String name;
  final String address;
  final String district;
  final LatLng location;
  final String description;
  final List<String> tags;

  /// 1 = cheap, 3 = pricey.
  final int priceLevel;

  /// Price of a typical beer in PLN.
  final double beerPrice;

  /// Lesser-known bar – visiting it gives bonus points.
  final bool isHiddenGem;
  final String openHours;
  final String emoji;

  String get qrPayload => '$qrPrefix$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'district': district,
        'lat': location.latitude,
        'lng': location.longitude,
        'description': description,
        'tags': tags,
        'priceLevel': priceLevel,
        'beerPrice': beerPrice,
        'isHiddenGem': isHiddenGem,
        'openHours': openHours,
        'emoji': emoji,
      };
}
