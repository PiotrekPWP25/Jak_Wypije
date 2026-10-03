import '../../core/utils/time.dart';
import '../../data/models/bar.dart';
import '../../data/models/check_in.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import 'scoring.dart';

enum ChallengeMetric {
  podgorzeCheckIns,
  landmarks,
  walkedKm,
  offPeak,
  newPlaces,
  barrierFree,
}

/// Weekly challenge – a reason for locals to come back every week.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.target,
    required this.rewardXp,
    required this.metric,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int target;
  final int rewardXp;
  final ChallengeMetric metric;
}

const List<Challenge> allChallenges = [
  Challenge(
    id: 'podgorze',
    title: 'Tydzień Podgórza',
    description: '2 meldunki w Podgórzu (dzielnica XIII)',
    emoji: '🌉',
    target: 2,
    rewardXp: 40,
    metric: ChallengeMetric.podgorzeCheckIns,
  ),
  Challenge(
    id: 'history',
    title: 'Śladami historii',
    description: 'Odwiedź 3 atrakcje miasta',
    emoji: '🏛️',
    target: 3,
    rewardXp: 40,
    metric: ChallengeMetric.landmarks,
  ),
  Challenge(
    id: 'walker',
    title: 'Spacerowicz',
    description: 'Przejdź 5 km między przystankami',
    emoji: '🚶',
    target: 5,
    rewardXp: 50,
    metric: ChallengeMetric.walkedKm,
  ),
  Challenge(
    id: 'off_peak',
    title: 'Poza tłokiem',
    description: '3 meldunki w strefach bez tłumów',
    emoji: '🌿',
    target: 3,
    rewardXp: 40,
    metric: ChallengeMetric.offPeak,
  ),
  Challenge(
    id: 'new_place',
    title: 'Coś nowego',
    description: 'Odwiedź miejsce oznaczone jako „Nowe”',
    emoji: '✨',
    target: 1,
    rewardXp: 30,
    metric: ChallengeMetric.newPlaces,
  ),
  Challenge(
    id: 'barrier_free',
    title: 'Bez barier',
    description: 'Odwiedź 2 lokale dostępne bez barier',
    emoji: '♿',
    target: 2,
    rewardXp: 30,
    metric: ChallengeMetric.barrierFree,
  ),
];

/// Monday of the first rotation week (5 January 2026).
final DateTime _rotationStart = DateTime.utc(2026, 1, 5);

/// Three challenges rotate every week.
List<Challenge> challengesForWeek(DateTime now) {
  final start = weekStart(now);
  final week = DateTime.utc(start.year, start.month, start.day)
          .difference(_rotationStart)
          .inDays ~/
      7;
  final n = allChallenges.length;
  final i = ((week % n) + n) % n;
  return [
    allChallenges[i],
    allChallenges[(i + 2) % n],
    allChallenges[(i + 4) % n],
  ];
}

class ChallengeProgress {
  const ChallengeProgress({required this.challenge, required this.value});

  final Challenge challenge;
  final int value;

  bool get completed => value >= challenge.target;

  double get progress => (value / challenge.target).clamp(0.0, 1.0);
}

List<ChallengeProgress> challengeProgress({
  required List<Challenge> challenges,
  required List<CheckIn> weekCheckIns,
  required Map<String, Place> placesById,
  required double walkedMeters,
}) {
  final visited =
      weekCheckIns.map((c) => placesById[c.placeId]).nonNulls.toSet();

  int valueOf(ChallengeMetric metric) => switch (metric) {
        ChallengeMetric.podgorzeCheckIns =>
          weekCheckIns.where((c) => districtOf(c, placesById) == 13).length,
        ChallengeMetric.landmarks => visited.whereType<Landmark>().length,
        ChallengeMetric.walkedKm => walkedMeters ~/ 1000,
        ChallengeMetric.offPeak => weekCheckIns.where((c) => c.offPeak).length,
        ChallengeMetric.newPlaces => visited.where((p) => p.isNew).length,
        ChallengeMetric.barrierFree => visited
            .whereType<Bar>()
            .where((bar) => bar.accessibility.isBarrierFree)
            .length,
      };

  return [
    for (final challenge in challenges)
      ChallengeProgress(challenge: challenge, value: valueOf(challenge.metric)),
  ];
}

int challengeXp(List<ChallengeProgress> progress) => progress
    .where((p) => p.completed)
    .fold(0, (sum, p) => sum + p.challenge.rewardXp);
