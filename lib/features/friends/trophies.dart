import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../profile/profile_providers.dart';

enum TrophyTier { none, bronze, silver, gold }

extension TrophyTierX on TrophyTier {
  String get label => switch (this) {
        TrophyTier.none => 'Brak',
        TrophyTier.bronze => 'Brąz',
        TrophyTier.silver => 'Srebro',
        TrophyTier.gold => 'Złoto',
      };

  Color? get color => switch (this) {
        TrophyTier.none => null,
        TrophyTier.bronze => AppColors.bronze,
        TrophyTier.silver => AppColors.silver,
        TrophyTier.gold => AppColors.gold,
      };
}

/// A tiered trophy: bronze / silver / gold thresholds of one stat.
class TrophyDefinition {
  const TrophyDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.thresholds,
    required this.metric,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;

  /// Values needed for bronze, silver and gold.
  final List<int> thresholds;
  final int Function(ProfileStats stats) metric;
}

class TrophyProgress {
  const TrophyProgress({required this.definition, required this.value});

  final TrophyDefinition definition;
  final int value;

  TrophyTier get tier {
    final t = definition.thresholds;
    if (value >= t[2]) return TrophyTier.gold;
    if (value >= t[1]) return TrophyTier.silver;
    if (value >= t[0]) return TrophyTier.bronze;
    return TrophyTier.none;
  }

  /// Next threshold to reach, `null` once gold is earned.
  int? get nextThreshold =>
      definition.thresholds.where((t) => value < t).firstOrNull;

  double get progressToNext {
    final next = nextThreshold;
    if (next == null) return 1.0;
    return (value / next).clamp(0.0, 1.0);
  }
}

int _uniqueBars(ProfileStats s) => s.uniqueBars;
int _hiddenGems(ProfileStats s) => s.hiddenGems;
int _offPeak(ProfileStats s) => s.offPeakCheckIns;
int _districts(ProfileStats s) => s.districts;
int _barrierFree(ProfileStats s) => s.barrierFreeBars;
int _safeReturns(ProfileStats s) => s.safeReturns;
int _reviews(ProfileStats s) => s.reviews;
int _planStops(ProfileStats s) => s.planStops;

const List<TrophyDefinition> allTrophies = [
  TrophyDefinition(
    id: 'explorer',
    title: 'Odkrywca',
    description: 'Odwiedzaj różne bary.',
    emoji: '🧭',
    thresholds: [3, 5, 10],
    metric: _uniqueBars,
  ),
  TrophyDefinition(
    id: 'gems',
    title: 'Łowca perełek',
    description: 'Zamelduj się w ukrytych perełkach.',
    emoji: '💎',
    thresholds: [1, 3, 6],
    metric: _hiddenGems,
  ),
  TrophyDefinition(
    id: 'off_peak',
    title: 'Poza utartym szlakiem',
    description: 'Meldunki w strefach bez tłoku – odciążasz Kazimierz i Rynek.',
    emoji: '🌿',
    thresholds: [1, 3, 6],
    metric: _offPeak,
  ),
  TrophyDefinition(
    id: 'districts',
    title: 'Obieżyświat',
    description: 'Poznaj bary w różnych dzielnicach.',
    emoji: '🗺️',
    thresholds: [2, 3, 5],
    metric: _districts,
  ),
  TrophyDefinition(
    id: 'barrier_free',
    title: 'Bez barier',
    description: 'Odwiedzaj lokale dostępne dla osób z niepełnosprawnościami.',
    emoji: '♿',
    thresholds: [1, 3, 5],
    metric: _barrierFree,
  ),
  TrophyDefinition(
    id: 'safe_return',
    title: 'Bezpieczny powrót',
    description: 'Wracaj komunikacją nocną zaplanowaną w aplikacji.',
    emoji: '🚋',
    thresholds: [1, 3, 5],
    metric: _safeReturns,
  ),
  TrophyDefinition(
    id: 'critic',
    title: 'Krytyk',
    description: 'Oceniaj bary dla znajomych.',
    emoji: '📝',
    thresholds: [1, 3, 6],
    metric: _reviews,
  ),
  TrophyDefinition(
    id: 'strategist',
    title: 'Strateg',
    description: 'Zaplanuj Barobranie z kilkoma przystankami.',
    emoji: '🗓️',
    thresholds: [2, 3, 5],
    metric: _planStops,
  ),
];
