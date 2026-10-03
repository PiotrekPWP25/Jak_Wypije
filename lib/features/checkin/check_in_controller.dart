import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/bar.dart';
import '../../data/models/check_in.dart';
import '../../data/models/fundraiser.dart';

class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.message,
    this.points = 0,
    this.bonuses = const [],
  });

  final bool success;
  final String message;
  final int points;
  final List<String> bonuses;
}

class CheckInsNotifier extends Notifier<List<CheckIn>> {
  static const int basePoints = 10;
  static const int firstVisitBonus = 5;
  static const int hiddenGemBonus = 15;
  static const int rescueBonus = 10;

  @override
  List<CheckIn> build() => ref.watch(localStorageProvider).loadCheckIns();

  /// Registers a visit. One check-in per bar per evening.
  CheckInResult checkIn(
    Bar bar, {
    required CheckInMethod method,
    Fundraiser? fundraiser,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final alreadyToday = state.any(
      (checkIn) =>
          checkIn.barId == bar.id && isSameEvening(checkIn.timestamp, at),
    );
    if (alreadyToday) {
      return CheckInResult(
        success: false,
        message: '${bar.name} masz już dziś zaliczony – wróć jutro!',
      );
    }

    var points = basePoints;
    final bonuses = <String>[];
    if (!state.any((checkIn) => checkIn.barId == bar.id)) {
      points += firstVisitBonus;
      bonuses.add('Pierwsza wizyta +$firstVisitBonus');
    }
    if (bar.isHiddenGem) {
      points += hiddenGemBonus;
      bonuses.add('Ukryta perełka +$hiddenGemBonus');
    }
    if (fundraiser != null && !fundraiser.isSaved) {
      points += rescueBonus;
      bonuses.add('Wspierasz ratowany bar +$rescueBonus');
    }

    final checkIn = CheckIn(
      barId: bar.id,
      timestamp: at,
      points: points,
      method: method,
    );
    state = List<CheckIn>.unmodifiable([checkIn, ...state]);
    ref.read(localStorageProvider).saveCheckIns(state);
    return CheckInResult(
      success: true,
      message: 'Zameldowano w: ${bar.name}',
      points: points,
      bonuses: bonuses,
    );
  }
}

final checkInsProvider = NotifierProvider<CheckInsNotifier, List<CheckIn>>(
  CheckInsNotifier.new,
);

/// An "evening" lasts until 6 a.m. of the next day.
bool isSameEvening(DateTime a, DateTime b) {
  const shift = Duration(hours: 6);
  final x = a.subtract(shift);
  final y = b.subtract(shift);
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Extracts the bar id from a `jakwypije:bar:<id>` QR payload.
String? parseBarQr(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (!value.startsWith(Bar.qrPrefix)) return null;
  final id = value.substring(Bar.qrPrefix.length).trim();
  return id.isEmpty ? null : id;
}
