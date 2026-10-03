import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/bar.dart';
import '../../data/models/evening_plan.dart';
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

  void add(String barId) {
    if (state.barIds.contains(barId)) return;
    _update(state.copyWith(barIds: [...state.barIds, barId]));
  }

  void remove(String barId) {
    _update(
      state.copyWith(barIds: state.barIds.where((id) => id != barId).toList()),
    );
  }

  void toggle(String barId) {
    if (state.barIds.contains(barId)) {
      remove(barId);
    } else {
      add(barId);
    }
  }

  /// Swaps [oldId] for [newId] in place (e.g. a calmer alternative).
  void replace(String oldId, String newId) {
    if (state.barIds.contains(newId)) return;
    _update(
      state.copyWith(
        barIds: [for (final id in state.barIds) id == oldId ? newId : id],
      ),
    );
  }

  /// [newIndex] is the final position after removing the item at [oldIndex].
  void moveStop(int oldIndex, int newIndex) {
    final ids = [...state.barIds];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    _update(state.copyWith(barIds: ids));
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

  void optimize(List<Bar> stops) =>
      _update(state.copyWith(barIds: optimizeRoute(stops)));

  void clear() => _update(state.copyWith(barIds: const []));
}

final plannerProvider = NotifierProvider<PlannerNotifier, EveningPlan>(
  PlannerNotifier.new,
);
