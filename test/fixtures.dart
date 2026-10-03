import 'package:jak_wypije/data/models/bar.dart';
import 'package:jak_wypije/data/models/city_zone.dart';
import 'package:jak_wypije/data/models/review.dart';

/// Test bar with sensible defaults; override any JSON field via [extra].
Bar testBar(
  String id, {
  double lat = 50.05,
  double lng = 19.94,
  String zoneId = 'calm',
  Map<String, dynamic> extra = const {},
}) {
  return Bar.fromJson({
    'id': id,
    'name': 'Bar $id',
    'address': 'ul. Testowa 1',
    'district': 'Kazimierz',
    'zoneId': zoneId,
    'lat': lat,
    'lng': lng,
    'tags': ['test'],
    'beer': {'min': 10, 'max': 12},
    'opensAt': '16:00',
    'closesAt': '02:00',
    'publicRating': 4.0,
    'publicRatingCount': 100,
    ...extra,
  });
}

CityZone testZone(
  String id, {
  required int crowd,
  bool quietZone = false,
}) {
  return CityZone.fromJson({
    'id': id,
    'name': 'Strefa $id',
    'lat': 50.05,
    'lng': 19.94,
    'radiusMeters': 500,
    'crowdByHour': List<int>.filled(9, crowd),
    'quietZone': quietZone,
  });
}

Review testReview(String barId, int rating, {String author = 'f1'}) {
  return Review(
    id: 'r-$barId-$author-$rating',
    barId: barId,
    authorId: author,
    rating: rating,
    comment: '',
    createdAt: DateTime(2026, 9, 30),
  );
}
