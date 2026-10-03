import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import 'plan_calculator.dart';

class PlannerNotifier extends Notifier<EveningPlan> {
  static const int maxDrinksPerStop = 6;

  @override
  EveningPlan build() =>
      ref.watch(localStorageProvider).loadPlan() ?? EveningPlan.initial;

  void _update(EveningPlan plan) {
    state = plan;
    ref.read(localStorageProvider).savePlan(plan);
  }

  void add(String placeId) {
    if (state.stopIds.contains(placeId)) return;
    _update(state.copyWith(stopIds: [...state.stopIds, placeId]));
  }

  void remove(String placeId) {
    _update(
      state.copyWith(
        stopIds: state.stopIds.where((id) => id != placeId).toList(),
      ),
    );
  }

  void toggle(String placeId) {
    if (state.stopIds.contains(placeId)) {
      remove(placeId);
    } else {
      add(placeId);
    }
  }

  /// Swaps [oldId] for [newId] in place (e.g. a calmer alternative).
  void replace(String oldId, String newId) {
    if (state.stopIds.contains(newId)) return;
    _update(
      state.copyWith(
        stopIds: [for (final id in state.stopIds) id == oldId ? newId : id],
      ),
    );
  }

  /// Replaces the route with a curated trip.
  void loadTrip(Trip trip) => _update(
        state.copyWith(
          stopIds: trip.stopIds,
          startMinutes: trip.startMinutes,
        ),
      );

  /// [newIndex] is the final position after removing the item at [oldIndex].
  void moveStop(int oldIndex, int newIndex) {
    final ids = [...state.stopIds];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    _update(state.copyWith(stopIds: ids));
  }

  void setStartMinutes(int minutes) =>
      _update(state.copyWith(startMinutes: minutes));

  void setDrinksPerStop(int drinks) => _update(
        state.copyWith(
          drinksPerStop: math.min(maxDrinksPerStop, math.max(1, drinks)),
        ),
      );

  void setMinutesPerStop(int minutes) =>
      _update(state.copyWith(minutesPerStop: minutes));

  void optimize(List<Place> stops) =>
      _update(state.copyWith(stopIds: optimizeRoute(stops)));

  void clear() => _update(state.copyWith(stopIds: const []));
}

final plannerProvider = NotifierProvider<PlannerNotifier, EveningPlan>(
  PlannerNotifier.new,
);
