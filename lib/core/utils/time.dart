/// Times on the "evening axis": minutes from midnight of the day the evening
/// starts. Night hours continue past 24:00 (01:30 → 25 * 60 + 30), so an
/// evening never wraps around.
library;

const int _nightEndsAt = 6 * 60;

/// Minutes on the evening axis for [time] (before 6:00 counts as the night).
int eveningMinutes(DateTime time) {
  final minutes = time.hour * 60 + time.minute;
  return minutes < _nightEndsAt ? minutes + 24 * 60 : minutes;
}

/// Parses `HH:mm` onto the evening axis (`01:30` → 1530).
int parseEveningTime(String value) {
  final parts = value.split(':');
  final minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  return minutes < _nightEndsAt ? minutes + 24 * 60 : minutes;
}

/// Clock used for live city data (crowds, "open now").
///
/// During the day there is no nightlife to measure, so the app shows the
/// forecast for 21:00 instead and says so in the UI.
class CityClock {
  const CityClock({required this.minutes, required this.isForecast});

  factory CityClock.of(DateTime now) {
    final minutes = eveningMinutes(now);
    if (minutes >= _nightEndsAt && minutes < 18 * 60) {
      return const CityClock(minutes: 21 * 60, isForecast: true);
    }
    return CityClock(minutes: minutes, isForecast: false);
  }

  final int minutes;
  final bool isForecast;
}

/// Monday 00:00 of the week containing [now] (leagues reset weekly).
DateTime weekStart(DateTime now) =>
    // Calendar arithmetic (not Duration) stays at midnight across DST changes.
    DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));
