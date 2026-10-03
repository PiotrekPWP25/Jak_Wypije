import 'package:latlong2/latlong.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';
import 'price_range.dart';

class BarAccessibility {
  const BarAccessibility({
    required this.stepFree,
    required this.accessibleToilet,
    required this.quietArea,
  });

  factory BarAccessibility.fromJson(Map<String, dynamic>? json) {
    return BarAccessibility(
      stepFree: json?['stepFree'] as bool? ?? false,
      accessibleToilet: json?['accessibleToilet'] as bool? ?? false,
      quietArea: json?['quietArea'] as bool? ?? false,
    );
  }

  /// Step-free entrance (or lift / ramp).
  final bool stepFree;
  final bool accessibleToilet;

  /// A calmer room or corner – helpful for sensory-sensitive guests.
  final bool quietArea;

  bool get isBarrierFree => stepFree && accessibleToilet;

  Map<String, dynamic> toJson() => {
        'stepFree': stepFree,
        'accessibleToilet': accessibleToilet,
        'quietArea': quietArea,
      };
}

/// A bar in Kraków. All names in the mock data are fictional.
class Bar {
  const Bar({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.zoneId,
    required this.location,
    required this.description,
    required this.tags,
    required this.emoji,
    required this.isHiddenGem,
    required this.beer,
    required this.shot,
    required this.drink,
    required this.food,
    required this.acceptsCards,
    required this.kitchenUntil,
    required this.opensAt,
    required this.closesAt,
    required this.publicRating,
    required this.publicRatingCount,
    required this.accessibility,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    PriceRange? range(String key) {
      final value = json[key];
      return value == null
          ? null
          : PriceRange.fromJson(value as Map<String, dynamic>);
    }

    final kitchenUntil = json['kitchenUntil'] as String?;
    return Bar(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      zoneId: json['zoneId'] as String? ?? '',
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      description: json['description'] as String? ?? '',
      tags: List<String>.unmodifiable(
        (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      ),
      emoji: json['emoji'] as String? ?? '🍺',
      isHiddenGem: json['isHiddenGem'] as bool? ?? false,
      beer: range('beer') ?? const PriceRange(min: 12, max: 16),
      shot: range('shot'),
      drink: range('drink'),
      food: range('food'),
      acceptsCards: json['acceptsCards'] as bool? ?? true,
      kitchenUntil:
          kitchenUntil == null ? null : parseEveningTime(kitchenUntil),
      opensAt: parseEveningTime(json['opensAt'] as String? ?? '16:00'),
      closesAt: parseEveningTime(json['closesAt'] as String? ?? '02:00'),
      publicRating: (json['publicRating'] as num?)?.toDouble() ?? 0,
      publicRatingCount: (json['publicRatingCount'] as num?)?.toInt() ?? 0,
      accessibility: BarAccessibility.fromJson(
        json['accessibility'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Payload encoded in the QR sticker placed in every partner bar.
  static const String qrPrefix = 'jakwypije:bar:';

  /// Kitchen open at least until this time counts as "late kitchen".
  static const int lateKitchenFrom = 22 * 60;

  final String id;
  final String name;
  final String address;
  final String district;

  /// City zone used for crowd levels and quiet-hours info.
  final String zoneId;
  final LatLng location;
  final String description;
  final List<String> tags;
  final String emoji;

  /// Lesser-known bar – visiting it gives bonus points.
  final bool isHiddenGem;

  /// Price ranges in PLN; `null` when the bar does not serve it.
  final PriceRange beer;
  final PriceRange? shot;
  final PriceRange? drink;
  final PriceRange? food;

  final bool acceptsCards;

  /// Last kitchen order on the evening axis; `null` = no kitchen.
  final int? kitchenUntil;

  /// Opening hours on the evening axis (closing may exceed 24:00).
  final int opensAt;
  final int closesAt;

  /// Average rating from all guests (secondary to friends' rating).
  final double publicRating;
  final int publicRatingCount;
  final BarAccessibility accessibility;

  String get qrPayload => '$qrPrefix$id';

  String get openHours => '${formatClock(opensAt)}–${formatClock(closesAt)}';

  bool get hasLateKitchen {
    final kitchen = kitchenUntil;
    return kitchen != null && kitchen >= lateKitchenFrom;
  }

  /// [minutes] on the evening axis.
  bool isOpenAt(int minutes) => minutes >= opensAt && minutes < closesAt;

  Map<String, dynamic> toJson() {
    final kitchen = kitchenUntil;
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'zoneId': zoneId,
      'lat': location.latitude,
      'lng': location.longitude,
      'description': description,
      'tags': tags,
      'emoji': emoji,
      'isHiddenGem': isHiddenGem,
      'beer': beer.toJson(),
      'shot': shot?.toJson(),
      'drink': drink?.toJson(),
      'food': food?.toJson(),
      'acceptsCards': acceptsCards,
      'kitchenUntil': kitchen == null ? null : formatClock(kitchen),
      'opensAt': formatClock(opensAt),
      'closesAt': formatClock(closesAt),
      'publicRating': publicRating,
      'publicRatingCount': publicRatingCount,
      'accessibility': accessibility.toJson(),
    };
  }
}
