import 'package:latlong2/latlong.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';
import 'place.dart';
import 'price_range.dart';

enum LandmarkCategory { monument, viewpoint, museum, streetArt, park }

extension LandmarkCategoryX on LandmarkCategory {
  String get label => switch (this) {
        LandmarkCategory.monument => 'Zabytek',
        LandmarkCategory.viewpoint => 'Punkt widokowy',
        LandmarkCategory.museum => 'Muzeum',
        LandmarkCategory.streetArt => 'Street art',
        LandmarkCategory.park => 'Park i bulwary',
      };
}

/// A city attraction that can be mixed with bars in a route.
class Landmark implements Place {
  const Landmark({
    required this.id,
    required this.name,
    required this.district,
    required this.districtNo,
    required this.zoneId,
    required this.location,
    required this.description,
    required this.category,
    required this.emoji,
    required this.visitMinutes,
    this.opensAt,
    this.closesAt,
    this.ticket,
    this.isNew = false,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    final opens = json['opensAt'] as String?;
    final closes = json['closesAt'] as String?;
    final ticket = json['ticket'] as Map<String, dynamic>?;
    return Landmark(
      id: json['id'] as String,
      name: json['name'] as String,
      district: json['district'] as String,
      districtNo: (json['districtNo'] as num?)?.toInt() ?? 0,
      zoneId: json['zoneId'] as String? ?? '',
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      description: json['description'] as String? ?? '',
      category: LandmarkCategory.values.byName(json['category'] as String),
      emoji: json['emoji'] as String? ?? '📍',
      visitMinutes: (json['visitMinutes'] as num?)?.toInt() ?? 30,
      opensAt: opens == null ? null : parseEveningTime(opens),
      closesAt: closes == null ? null : parseEveningTime(closes),
      ticket: ticket == null ? null : PriceRange.fromJson(ticket),
      isNew: json['isNew'] as bool? ?? false,
    );
  }

  @override
  final String id;
  @override
  final String name;
  @override
  final String district;
  @override
  final int districtNo;
  @override
  final String zoneId;
  @override
  final LatLng location;
  final String description;
  final LandmarkCategory category;
  @override
  final String emoji;

  /// Suggested time to spend there.
  final int visitMinutes;

  /// Opening hours on the evening axis; both `null` = always accessible.
  final int? opensAt;
  final int? closesAt;

  /// Entry ticket; `null` = free.
  final PriceRange? ticket;
  @override
  final bool isNew;

  @override
  PlaceType get type => PlaceType.landmark;

  bool get isAlwaysOpen => opensAt == null || closesAt == null;

  String get openHours {
    final opens = opensAt;
    final closes = closesAt;
    if (opens == null || closes == null) return 'całą dobę';
    return '${formatClock(opens)}–${formatClock(closes)}';
  }

  String get ticketLabel => ticket?.label ?? 'bezpłatne';

  @override
  bool isOpenAt(int minutes) {
    final opens = opensAt;
    final closes = closesAt;
    if (opens == null || closes == null) return true;
    return minutes >= opens && minutes < closes;
  }

  Map<String, dynamic> toJson() {
    final opens = opensAt;
    final closes = closesAt;
    return {
      'id': id,
      'name': name,
      'district': district,
      'districtNo': districtNo,
      'zoneId': zoneId,
      'lat': location.latitude,
      'lng': location.longitude,
      'description': description,
      'category': category.name,
      'emoji': emoji,
      'visitMinutes': visitMinutes,
      'opensAt': opens == null ? null : formatClock(opens),
      'closesAt': closes == null ? null : formatClock(closes),
      'ticket': ticket?.toJson(),
      'isNew': isNew,
    };
  }
}
