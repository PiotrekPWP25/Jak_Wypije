import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/models/bar.dart';
import 'package:jak_wypije/data/models/city_district.dart';
import 'package:jak_wypije/data/models/city_event.dart';
import 'package:jak_wypije/data/models/evening_plan.dart';
import 'package:jak_wypije/data/models/landmark.dart';
import 'package:jak_wypije/data/models/place.dart';
import 'package:jak_wypije/data/models/trip.dart';
import 'package:jak_wypije/features/barobranie/plan_calculator.dart';

List<Map<String, dynamic>> _load(String name) =>
    (jsonDecode(File('assets/data/$name.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

void main() {
  final bars = _load('bars').map(Bar.fromJson).toList();
  final landmarks = _load('landmarks').map(Landmark.fromJson).toList();
  final trips = _load('trips').map(Trip.fromJson).toList();
  final events = _load('events').map(CityEvent.fromJson).toList();
  final districts = _load('districts').map(CityDistrict.fromJson).toList();
  final places = <String, Place>{
    for (final place in <Place>[...bars, ...landmarks]) place.id: place,
  };

  test('ids are unique across bars and landmarks', () {
    expect(places.length, bars.length + landmarks.length);
  });

  test('every place belongs to one of the 18 districts', () {
    expect(districts.map((d) => d.no), List.generate(18, (i) => i + 1));
    for (final place in places.values) {
      expect(place.districtNo, inInclusiveRange(1, 18), reason: place.id);
    }
  });

  test('trips and events point to existing places', () {
    for (final trip in trips) {
      for (final id in trip.stopIds) {
        expect(places.containsKey(id), isTrue, reason: '${trip.id}: $id');
      }
      expect(
        trip.stopIds.any((id) => places[id] is Landmark),
        isTrue,
        reason: '${trip.id} should include a landmark',
      );
    }
    for (final event in events) {
      expect(places.containsKey(event.placeId), isTrue, reason: event.id);
    }
  });

  test('curated trips never arrive at a closed place', () {
    for (final trip in trips) {
      final plan = EveningPlan.initial.copyWith(
        stopIds: trip.stopIds,
        startMinutes: trip.startMinutes,
      );
      final summary = calculatePlan(plan, resolveStops(plan, places));
      final closed = [
        for (final stop in summary.stops)
          for (final warning in stop.warnings)
            if (warning.type == PlanWarningType.closed) stop.place.id,
      ];
      expect(closed, isEmpty, reason: trip.id);
    }
  });
}
