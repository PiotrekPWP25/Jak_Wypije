import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/check_in.dart';
import '../models/evening_plan.dart';
import '../models/review.dart';
import '../models/user_profile.dart';

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

  static const String defaultUserName = UserProfile.defaultName;

  static const String _checkInsKey = 'check_ins';
  static const String _planKey = 'evening_plan';
  static const String _myReviewsKey = 'my_reviews';
  static const String _userNameKey = 'user_name';
  static const String _themeModeKey = 'theme_mode';
  static const String _safeReturnsKey = 'safe_returns';
  static const String _userModeKey = 'user_mode';
  static const String _avatarKey = 'avatar_emoji';
  static const String _ageConfirmedKey = 'age_confirmed_at';
  static const String _termsVersionKey = 'terms_version';
  static const String _termsAcceptedKey = 'terms_accepted_at';
  static const String _marketingKey = 'marketing_consent';
  static const String _profileDirtyKey = 'profile_dirty';

  /// Everything the user created on this device (cleared by "Wyczyść dane").
  /// The theme stays – it is a device preference, not personal data.
  static const List<String> _userDataKeys = [
    _checkInsKey,
    _planKey,
    _myReviewsKey,
    _userNameKey,
    _safeReturnsKey,
    _userModeKey,
    _avatarKey,
    _ageConfirmedKey,
    _termsVersionKey,
    _termsAcceptedKey,
    _marketingKey,
    _profileDirtyKey,
  ];

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

  /// Profile assembled from the individual keys the notifiers use.
  UserProfile loadProfile() => UserProfile(
        displayName: loadUserName(),
        avatarEmoji: _prefs.getString(_avatarKey) ?? UserProfile.defaultAvatar,
        userMode: loadUserMode(),
        themeMode: loadThemeMode().name,
        ageConfirmedAt: _readDate(_ageConfirmedKey),
        termsVersion: _prefs.getInt(_termsVersionKey) ?? 0,
        termsAcceptedAt: _readDate(_termsAcceptedKey),
        marketingConsent: _prefs.getBool(_marketingKey) ?? false,
      );

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_userNameKey, profile.displayName);
    await _prefs.setString(_avatarKey, profile.avatarEmoji);
    final mode = profile.userMode;
    if (mode != null) await _prefs.setString(_userModeKey, mode);
    final theme = profile.themeMode;
    if (theme != null) await _prefs.setString(_themeModeKey, theme);
    await _writeDate(_ageConfirmedKey, profile.ageConfirmedAt);
    await _prefs.setInt(_termsVersionKey, profile.termsVersion);
    await _writeDate(_termsAcceptedKey, profile.termsAcceptedAt);
    await _prefs.setBool(_marketingKey, profile.marketingConsent);
  }

  /// `true` while a profile change still has to reach the account.
  bool loadProfileDirty() => _prefs.getBool(_profileDirtyKey) ?? false;

  Future<void> saveProfileDirty(bool dirty) async {
    await _prefs.setBool(_profileDirtyKey, dirty);
  }

  /// Everything stored about the user – for the GDPR data export.
  Map<String, dynamic> exportUserData() => {
        'profile': loadProfile().toJson(),
        'checkIns': [for (final checkIn in loadCheckIns()) checkIn.toJson()],
        'eveningPlan': loadPlan()?.toJson(),
        'myReviews': [for (final review in loadMyReviews()) review.toJson()],
        'safeReturns': loadSafeReturns(),
      };

  Future<void> clearUserData() async {
    for (final key in _userDataKeys) {
      await _prefs.remove(key);
    }
  }

  DateTime? _readDate(String key) {
    final raw = _prefs.getString(key);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _writeDate(String key, DateTime? value) async {
    if (value == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value.toUtc().toIso8601String());
    }
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
