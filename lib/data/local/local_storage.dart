import 'dart:convert';

import 'package:flutter/material.dart';
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

/// Persists user-generated state (check-ins, plan, reviews, settings).
class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String defaultUserName = 'Ty';

  static const String _checkInsKey = 'check_ins';
  static const String _planKey = 'evening_plan';
  static const String _myReviewsKey = 'my_reviews';
  static const String _userNameKey = 'user_name';
  static const String _themeModeKey = 'theme_mode';
  static const String _safeReturnsKey = 'safe_returns';
  static const String _userModeKey = 'user_mode';

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

  List<Review> loadMyReviews() =>
      List<Review>.unmodifiable(_readList(_myReviewsKey).map(Review.fromJson));

  Future<void> saveMyReviews(List<Review> reviews) =>
      _writeList(_myReviewsKey, reviews.map((review) => review.toJson()));

  String loadUserName() => _prefs.getString(_userNameKey) ?? defaultUserName;

  Future<void> saveUserName(String name) async {
    await _prefs.setString(_userNameKey, name);
  }

  /// Light (cream) is the default to match the logo.
  ThemeMode loadThemeMode() =>
      _prefs.getString(_themeModeKey) == ThemeMode.dark.name
          ? ThemeMode.dark
          : ThemeMode.light;

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  /// How many times the user started a planned safe ride home.
  int loadSafeReturns() => _prefs.getInt(_safeReturnsKey) ?? 0;

  Future<void> saveSafeReturns(int count) async {
    await _prefs.setInt(_safeReturnsKey, count);
  }

  /// `tourist` / `local`, or `null` before onboarding.
  String? loadUserMode() => _prefs.getString(_userModeKey);

  Future<void> saveUserMode(String mode) async {
    await _prefs.setString(_userModeKey, mode);
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
