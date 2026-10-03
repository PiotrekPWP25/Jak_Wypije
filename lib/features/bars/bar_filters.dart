import 'package:latlong2/latlong.dart';

import '../../core/utils/geo.dart';
import '../../data/models/bar.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/price_range.dart';
import '../../data/models/review.dart';

enum BarSort { friends, distance, beerPrice }

/// A bar enriched with data that depends on the user and the city "now".
class BarListing {
  const BarListing({
    required this.bar,
    required this.distanceMeters,
    required this.friendsRating,
    required this.friendsRatingCount,
    required this.crowd,
    required this.isOpen,
  });

  final Bar bar;

  /// Distance from the reference point (previous bar on the route or user).
  final double distanceMeters;

  /// Average of friends' reviews; `null` when no friend rated the bar.
  final double? friendsRating;
  final int friendsRatingCount;
  final CrowdLevel? crowd;
  final bool isOpen;
}

/// Booking-style filters. `null` ranges mean "any".
class BarFilters {
  const BarFilters({
    this.query = '',
    this.sort = BarSort.friends,
    this.beer,
    this.shot,
    this.drink,
    this.food,
    this.maxDistanceMeters,
    this.acceptsCards = false,
    this.lateKitchen = false,
    this.barrierFree = false,
    this.openNow = false,
    this.offPeak = false,
  });

  static const PriceRange beerBounds = PriceRange(min: 5, max: 30);
  static const PriceRange shotBounds = PriceRange(min: 5, max: 25);
  static const PriceRange drinkBounds = PriceRange(min: 10, max: 50);
  static const PriceRange foodBounds = PriceRange(min: 10, max: 80);
  static const double distanceBound = 5000;

  final String query;
  final BarSort sort;
  final PriceRange? beer;
  final PriceRange? shot;
  final PriceRange? drink;
  final PriceRange? food;
  final double? maxDistanceMeters;
  final bool acceptsCards;
  final bool lateKitchen;
  final bool barrierFree;
  final bool openNow;
  final bool offPeak;

  /// Number of active filters (search and sort excluded).
  int get activeCount => [
        beer != null,
        shot != null,
        drink != null,
        food != null,
        maxDistanceMeters != null,
        acceptsCards,
        lateKitchen,
        barrierFree,
        openNow,
        offPeak,
      ].where((active) => active).length;

  static const Object _keep = Object();

  BarFilters copyWith({
    String? query,
    BarSort? sort,
    Object? beer = _keep,
    Object? shot = _keep,
    Object? drink = _keep,
    Object? food = _keep,
    Object? maxDistanceMeters = _keep,
    bool? acceptsCards,
    bool? lateKitchen,
    bool? barrierFree,
    bool? openNow,
    bool? offPeak,
  }) {
    return BarFilters(
      query: query ?? this.query,
      sort: sort ?? this.sort,
      beer: identical(beer, _keep) ? this.beer : beer as PriceRange?,
      shot: identical(shot, _keep) ? this.shot : shot as PriceRange?,
      drink: identical(drink, _keep) ? this.drink : drink as PriceRange?,
      food: identical(food, _keep) ? this.food : food as PriceRange?,
      maxDistanceMeters: identical(maxDistanceMeters, _keep)
          ? this.maxDistanceMeters
          : maxDistanceMeters as double?,
      acceptsCards: acceptsCards ?? this.acceptsCards,
      lateKitchen: lateKitchen ?? this.lateKitchen,
      barrierFree: barrierFree ?? this.barrierFree,
      openNow: openNow ?? this.openNow,
      offPeak: offPeak ?? this.offPeak,
    );
  }

  /// Clears filters but keeps the search query and sort order.
  BarFilters cleared() => BarFilters(query: query, sort: sort);
}

List<BarListing> buildListings({
  required List<Bar> bars,
  required List<Review> reviews,
  required LatLng reference,
  required Map<String, CityZone> zones,
  required int nowMinutes,
}) {
  final friendRatings = <String, List<int>>{};
  for (final review in reviews) {
    if (review.isMine) continue;
    friendRatings.putIfAbsent(review.barId, () => []).add(review.rating);
  }
  return [
    for (final bar in bars)
      () {
        final ratings = friendRatings[bar.id] ?? const <int>[];
        return BarListing(
          bar: bar,
          distanceMeters: haversineMeters(reference, bar.location),
          friendsRating: ratings.isEmpty
              ? null
              : ratings.reduce((a, b) => a + b) / ratings.length,
          friendsRatingCount: ratings.length,
          crowd: zones[bar.zoneId]?.levelAt(nowMinutes),
          isOpen: bar.isOpenAt(nowMinutes),
        );
      }(),
  ];
}

bool _rangeMatches(PriceRange? barRange, PriceRange? filter) {
  if (filter == null) return true;
  if (barRange == null) return false;
  return barRange.overlaps(filter.min, filter.max);
}

List<BarListing> applyFilters(List<BarListing> listings, BarFilters filters) {
  final query = filters.query.trim().toLowerCase();
  return listings.where((listing) {
    final bar = listing.bar;
    if (query.isNotEmpty &&
        !bar.name.toLowerCase().contains(query) &&
        !bar.district.toLowerCase().contains(query) &&
        !bar.tags.any((tag) => tag.toLowerCase().contains(query))) {
      return false;
    }
    final maxDistance = filters.maxDistanceMeters;
    if (maxDistance != null && listing.distanceMeters > maxDistance) {
      return false;
    }
    return _rangeMatches(bar.beer, filters.beer) &&
        _rangeMatches(bar.shot, filters.shot) &&
        _rangeMatches(bar.drink, filters.drink) &&
        _rangeMatches(bar.food, filters.food) &&
        (!filters.acceptsCards || bar.acceptsCards) &&
        (!filters.lateKitchen || bar.hasLateKitchen) &&
        (!filters.barrierFree || bar.accessibility.isBarrierFree) &&
        (!filters.openNow || listing.isOpen) &&
        (!filters.offPeak || listing.crowd == CrowdLevel.low);
  }).toList();
}

/// Friends' rating first (unrated last), then the public rating and its
/// number of reviews – the core "trust your friends" ordering.
int compareByFriends(BarListing a, BarListing b) {
  final byFriends = (b.friendsRating ?? -1).compareTo(a.friendsRating ?? -1);
  if (byFriends != 0) return byFriends;
  final byPublic = b.bar.publicRating.compareTo(a.bar.publicRating);
  if (byPublic != 0) return byPublic;
  return b.bar.publicRatingCount.compareTo(a.bar.publicRatingCount);
}

List<BarListing> sortListings(List<BarListing> listings, BarSort sort) {
  final sorted = [...listings];
  switch (sort) {
    case BarSort.friends:
      sorted.sort(compareByFriends);
    case BarSort.distance:
      sorted.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    case BarSort.beerPrice:
      sorted.sort((a, b) {
        final byPrice = a.bar.beer.min.compareTo(b.bar.beer.min);
        return byPrice != 0 ? byPrice : compareByFriends(a, b);
      });
  }
  return sorted;
}
