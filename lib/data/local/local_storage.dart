import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/check_in.dart';
import '../models/evening_plan.dart';
import '../models/review.dart';

/// Overridden in `main()` with an already initialised instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(ref.watch(sharedPreferencesProvider)),
);

/// Persists user-generated state (check-ins, plan, pledges, reviews).
class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String defaultUserName = 'Ty';

  static const String _checkInsKey = 'check_ins';
  static const String _planKey = 'evening_plan';
  static const String _contributionsKey = 'contributions';
  static const String _myReviewsKey = 'my_reviews';
  static const String _userNameKey = 'user_name';

  List<CheckIn> loadCheckIns() =>
      List<CheckIn>.unmodifiable(_readList(_checkInsKey).map(CheckIn.fromJson));

  Future<void> saveCheckIns(List<CheckIn> checkIns) =>
      _writeList(_checkInsKey, checkIns.map((checkIn) => checkIn.toJson()));

  EveningPlan? loadPlan() {
    final raw = _prefs.getString(_planKey);
    if (raw == null) return null;
    try {
      return EveningPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> savePlan(EveningPlan plan) async {
    await _prefs.setString(_planKey, jsonEncode(plan.toJson()));
  }

  Map<String, double> loadContributions() {
    final raw = _prefs.getString(_contributionsKey);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return Map<String, double>.unmodifiable(
        decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      );
    } on FormatException {
      return const {};
    }
  }

  Future<void> saveContributions(Map<String, double> contributions) async {
    await _prefs.setString(_contributionsKey, jsonEncode(contributions));
  }

  List<Review> loadMyReviews() =>
      List<Review>.unmodifiable(_readList(_myReviewsKey).map(Review.fromJson));

  Future<void> saveMyReviews(List<Review> reviews) =>
      _writeList(_myReviewsKey, reviews.map((review) => review.toJson()));

  String loadUserName() => _prefs.getString(_userNameKey) ?? defaultUserName;

  Future<void> saveUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeList(
    String key,
    Iterable<Map<String, dynamic>> items,
  ) async {
    await _prefs.setString(key, jsonEncode(items.toList()));
  }
}
