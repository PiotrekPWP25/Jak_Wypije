import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/bar.dart';
import '../../data/models/check_in.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/place.dart';
import '../gamification/scoring.dart';

class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.message,
    this.points = 0,
    this.bonuses = const [],
    this.completedRoute = false,
  });

  final bool success;
  final String message;
  final int points;
  final List<String> bonuses;
  final bool completedRoute;
}

class CheckInsNotifier extends Notifier<List<CheckIn>> {
  @override
  List<CheckIn> build() => ref.watch(localStorageProvider).loadCheckIns();

  /// Registers a visit to a bar or a landmark. One check-in per place per
  /// evening; points follow [scoreCheckIn].
  CheckInResult checkIn(
    Place place, {
    required CheckInMethod method,
    Map<String, Place> placesById = const {},
    CityZone? zone,
    EveningPlan? plan,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final alreadyToday = state.any(
      (checkIn) =>
          checkIn.placeId == place.id && isSameEvening(checkIn.timestamp, at),
    );
    if (alreadyToday) {
      return CheckInResult(
        success: false,
        message: '${place.name} masz już dziś zaliczone – wróć innego dnia!',
      );
    }

    final score = scoreCheckIn(
      place: place,
      history: state,
      at: at,
      placesById: {...placesById, place.id: place},
      zone: zone,
      plan: plan,
    );
    final checkIn = CheckIn(
      placeId: place.id,
      timestamp: at,
      points: score.points,
      method: method,
      placeType: place.type,
      districtNo: place.districtNo,
      offPeak: score.offPeak,
      completedRoute: score.completedRoute,
    );
    state = List<CheckIn>.unmodifiable([checkIn, ...state]);
    ref.read(localStorageProvider).saveCheckIns(state);
    return CheckInResult(
      success: true,
      message: 'Zameldowano: ${place.name}',
      points: score.points,
      bonuses: score.bonuses,
      completedRoute: score.completedRoute,
    );
  }
}

final checkInsProvider = NotifierProvider<CheckInsNotifier, List<CheckIn>>(
  CheckInsNotifier.new,
);

/// Extracts the bar id from a `jakwypije:bar:<id>` QR payload.
String? parseBarQr(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (!value.startsWith(Bar.qrPrefix)) return null;
  final id = value.substring(Bar.qrPrefix.length).trim();
  return id.isEmpty ? null : id;
}
