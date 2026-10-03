import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/core/utils/geo.dart';
import 'package:jak_wypije/data/models/price_range.dart';
import 'package:jak_wypije/data/models/review.dart';
import 'package:jak_wypije/features/bars/bar_filters.dart';
import 'package:latlong2/latlong.dart';

import 'fixtures.dart';

void main() {
  final cheapNear = testBar(
    'cheap',
    lat: 50.0510,
    extra: {
      'beer': {'min': 8, 'max': 10},
      'publicRating': 4.9,
      'publicRatingCount': 50,
      'acceptsCards': false,
    },
  );
  final pricey = testBar(
    'pricey',
    lat: 50.0700,
    zoneId: 'busy',
    extra: {
      'beer': {'min': 18, 'max': 22},
      'shot': {'min': 12, 'max': 15},
      'food': {'min': 30, 'max': 40},
      'kitchenUntil': '23:00',
      'publicRating': 4.1,
      'publicRatingCount': 900,
      'accessibility': {'stepFree': true, 'accessibleToilet': true},
    },
  );
  final unrated = testBar(
    'unrated',
    lat: 50.0550,
    extra: {'publicRating': 4.5, 'publicRatingCount': 300, 'opensAt': '23:00'},
  );

  final reviews = [
    testReview('pricey', 5, author: 'f1'),
    testReview('pricey', 4, author: 'f2'),
    testReview('cheap', 4, author: 'f1'),
    // The user's own review is not a "friends" rating.
    testReview('unrated', 5, author: Review.myAuthorId),
  ];

  List<BarListing> listings({LatLng reference = krakowCenter}) => buildListings(
        bars: [cheapNear, pricey, unrated],
        reviews: reviews,
        reference: reference,
        zones: {
          'calm': testZone('calm', crowd: 10),
          'busy': testZone('busy', crowd: 95),
        },
        nowMinutes: 21 * 60,
      );

  test('friends rating is the average of friends reviews only', () {
    final byId = {for (final l in listings()) l.bar.id: l};
    expect(byId['pricey']!.friendsRating, 4.5);
    expect(byId['pricey']!.friendsRatingCount, 2);
    expect(byId['cheap']!.friendsRating, 4.0);
    expect(byId['unrated']!.friendsRating, isNull);
  });

  test('sorts by friends rating first, public rating second', () {
    final sorted = sortListings(listings(), BarSort.friends);
    expect(
      sorted.map((l) => l.bar.id),
      // pricey: friends 4.5 beats cheap (friends 4.0, public 4.9);
      // unrated (no friends rating) goes last despite public 4.5.
      ['pricey', 'cheap', 'unrated'],
    );
  });

  test('sorts by distance and by beer price', () {
    const reference = LatLng(50.0500, 19.94);
    expect(
      sortListings(listings(reference: reference), BarSort.distance)
          .map((l) => l.bar.id),
      ['cheap', 'unrated', 'pricey'],
    );
    expect(
      sortListings(listings(), BarSort.beerPrice).map((l) => l.bar.id).first,
      'cheap',
    );
  });

  test('distance filter is measured from the previous bar on the route', () {
    // Reference = previous stop right next to "cheap".
    final fromPrevious = listings(reference: cheapNear.location);
    final result = applyFilters(
      fromPrevious,
      const BarFilters(maxDistanceMeters: 600),
    );
    expect(result.map((l) => l.bar.id), ['cheap', 'unrated']);
  });

  test('price range filters overlap and drop bars without the item', () {
    final all = listings();
    expect(
      applyFilters(all, const BarFilters(beer: PriceRange(min: 5, max: 12)))
          .map((l) => l.bar.id),
      ['cheap', 'unrated'],
    );
    expect(
      applyFilters(all, const BarFilters(food: PriceRange(min: 30, max: 40)))
          .map((l) => l.bar.id),
      ['pricey'],
    );
    expect(
      applyFilters(all, const BarFilters(shot: PriceRange(min: 5, max: 10))),
      isEmpty,
    );
  });

  test('amenity and city filters', () {
    final all = listings();
    List<String> ids(BarFilters f) =>
        applyFilters(all, f).map((l) => l.bar.id).toList();

    expect(ids(const BarFilters(barrierFree: true)), ['pricey']);
    expect(ids(const BarFilters(acceptsCards: true)), ['pricey', 'unrated']);
    expect(ids(const BarFilters(lateKitchen: true)), ['pricey']);
    expect(ids(const BarFilters(openNow: true)), ['cheap', 'pricey']);
    expect(ids(const BarFilters(offPeak: true)), ['cheap', 'unrated']);
    expect(ids(const BarFilters(query: 'PRICEY')), ['pricey']);
  });

  test('copyWith can clear a range and activeCount tracks filters', () {
    const filters = BarFilters(
      beer: PriceRange(min: 5, max: 10),
      barrierFree: true,
    );
    expect(filters.activeCount, 2);
    final cleared = filters.copyWith(beer: null);
    expect(cleared.beer, isNull);
    expect(cleared.barrierFree, isTrue);
    expect(cleared.activeCount, 1);
    expect(filters.copyWith(query: 'x').beer, isNotNull);
    expect(filters.cleared().activeCount, 0);
  });
}
