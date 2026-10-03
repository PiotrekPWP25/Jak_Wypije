import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time.dart';
import '../../data/models/check_in.dart';
import '../../data/repositories/place_repository.dart';
import '../checkin/check_in_controller.dart';
import 'challenges.dart';
import 'scoring.dart';

/// Check-ins since Monday 00:00.
final weekCheckInsProvider = Provider<List<CheckIn>>((ref) {
  final start = weekStart(DateTime.now());
  return ref
      .watch(checkInsProvider)
      .where((checkIn) => !checkIn.timestamp.isBefore(start))
      .toList();
});

final walkedMetersTotalProvider = Provider<double>(
  (ref) => walkedMeters(
    ref.watch(checkInsProvider),
    ref.watch(placesByIdProvider),
  ),
);

final walkedMetersWeekProvider = Provider<double>(
  (ref) => walkedMeters(
    ref.watch(weekCheckInsProvider),
    ref.watch(placesByIdProvider),
  ),
);

final weeklyChallengesProvider = Provider<List<ChallengeProgress>>((ref) {
  return challengeProgress(
    challenges: challengesForWeek(DateTime.now()),
    weekCheckIns: ref.watch(weekCheckInsProvider),
    placesById: ref.watch(placesByIdProvider),
    walkedMeters: ref.watch(walkedMetersWeekProvider),
  );
});

final stampedDistrictsProvider = Provider<Set<int>>(
  (ref) => stampedDistricts(
    ref.watch(checkInsProvider),
    ref.watch(placesByIdProvider),
  ),
);
