import 'package:latlong2/latlong.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';
import 'place.dart';
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

/// A time-limited offer published by the venue (food, soft drinks, …).
class HappyHour {
  const HappyHour({
    required this.from,
    required this.to,
    required this.label,
  });

  factory HappyHour.fromJson(Map<String, dynamic> json) {
    return HappyHour(
      from: parseEveningTime(json['from'] as String),
      to: parseEveningTime(json['to'] as String),
      label: json['label'] as String,
    );
  }

  /// Window on the evening axis.
  final int from;
  final int to;
  final String label;

  bool isActiveAt(int minutes) => minutes >= from && minutes < to;

  String get hours => '${formatClock(from)}–${formatClock(to)}';

  Map<String, dynamic> toJson() => {
        'from': formatClock(from),
        'to': formatClock(to),
        'label': label,
      };
}

/// A bar in Kraków. All names in the mock data are fictional.
class Bar implements Place {
  const Bar({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.districtNo,
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
    this.nonAlcoholic = false,
    this.happyHour,
    this.isNew = false,
  });

  factory Bar.fromJson(Map<String, dynamic> json) {
    PriceRange? range(String key) {
      final value = json[key];
      return value == null
          ? null
          : PriceRange.fromJson(value as Map<String, dynamic>);
    }

    final kitchenUntil = json['kitchenUntil'] as String?;
    final happyHour = json['happyHour'] as Map<String, dynamic>?;
    return Bar(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      districtNo: (json['districtNo'] as num?)?.toInt() ?? 0,
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
      nonAlcoholic: json['nonAlcoholic'] as bool? ?? false,
      happyHour: happyHour == null ? null : HappyHour.fromJson(happyHour),
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  /// Payload encoded in the QR sticker placed in every partner bar.
  static const String qrPrefix = 'jakwypije:bar:';

  /// Kitchen open at least until this time counts as "late kitchen".
  static const int lateKitchenFrom = 22 * 60;

  @override
  final String id;
  @override
  final String name;
  final String address;
  @override
  final String district;
  @override
  final int districtNo;

  /// City zone used for crowd levels and quiet-hours info.
  @override
  final String zoneId;
  @override
  final LatLng location;
  final String description;
  final List<String> tags;
  @override
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

  /// Good non-alcoholic menu (0% beer, lemonades, …).
  final bool nonAlcoholic;
  final HappyHour? happyHour;
  @override
  final bool isNew;

  @override
  PlaceType get type => PlaceType.bar;

  String get qrPayload => '$qrPrefix$id';

  String get openHours => '${formatClock(opensAt)}–${formatClock(closesAt)}';

  bool get hasLateKitchen {
    final kitchen = kitchenUntil;
    return kitchen != null && kitchen >= lateKitchenFrom;
  }

  bool isHappyHourAt(int minutes) => happyHour?.isActiveAt(minutes) ?? false;

  /// [minutes] on the evening axis.
  @override
  bool isOpenAt(int minutes) => minutes >= opensAt && minutes < closesAt;

  Map<String, dynamic> toJson() {
    final kitchen = kitchenUntil;
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'districtNo': districtNo,
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
      'nonAlcoholic': nonAlcoholic,
      'happyHour': happyHour?.toJson(),
      'isNew': isNew,
    };
  }
}
