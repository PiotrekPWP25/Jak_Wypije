/// Profile and consents of the person using the app – stored on the device
/// and, when signed in, mirrored to the `profiles` table in Supabase.
class UserProfile {
  const UserProfile({
    this.displayName = defaultName,
    this.avatarEmoji = defaultAvatar,
    this.userMode,
    this.themeMode,
    this.ageConfirmedAt,
    this.termsVersion = 0,
    this.termsAcceptedAt,
    this.marketingConsent = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final name = (json['display_name'] as String?)?.trim();
    final avatar = json['avatar_emoji'] as String?;
    return UserProfile(
      displayName: name == null || name.isEmpty ? defaultName : name,
      avatarEmoji: avatar == null || avatar.isEmpty ? defaultAvatar : avatar,
      userMode: json['user_mode'] as String?,
      themeMode: json['theme_mode'] as String?,
      ageConfirmedAt: _parseDate(json['age_confirmed_at']),
      termsVersion: (json['terms_version'] as num?)?.toInt() ?? 0,
      termsAcceptedAt: _parseDate(json['terms_accepted_at']),
      marketingConsent: json['marketing_consent'] as bool? ?? false,
    );
  }

  static const String defaultName = 'Ty';
  static const String defaultAvatar = '🍺';
  static const int maxNameLength = 24;

  /// Avatars offered in Settings.
  static const List<String> avatars = [
    '🍺', '🚶', '🧭', '🏛️', '🐉', '🎨', //
    '🌿', '🚲', '🎧', '📸', '☕', '🦉',
  ];

  final String displayName;
  final String avatarEmoji;

  /// `tourist` / `local`, `null` before onboarding.
  final String? userMode;

  /// `light` / `dark`.
  final String? themeMode;

  /// When the user confirmed they are 18+ (`null` = not yet).
  final DateTime? ageConfirmedAt;

  /// Version of the Terms and Privacy Policy the user accepted (0 = none).
  final int termsVersion;
  final DateTime? termsAcceptedAt;
  final bool marketingConsent;

  bool get isAgeConfirmed => ageConfirmedAt != null;

  bool hasAcceptedTerms(int currentVersion) => termsVersion >= currentVersion;

  UserProfile copyWith({
    String? displayName,
    String? avatarEmoji,
    String? userMode,
    String? themeMode,
    DateTime? ageConfirmedAt,
    int? termsVersion,
    DateTime? termsAcceptedAt,
    bool? marketingConsent,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      userMode: userMode ?? this.userMode,
      themeMode: themeMode ?? this.themeMode,
      ageConfirmedAt: ageConfirmedAt ?? this.ageConfirmedAt,
      termsVersion: termsVersion ?? this.termsVersion,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      marketingConsent: marketingConsent ?? this.marketingConsent,
    );
  }

  /// Snake_case keys match the `profiles` columns.
  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'avatar_emoji': avatarEmoji,
        'user_mode': userMode,
        'theme_mode': themeMode,
        'age_confirmed_at': ageConfirmedAt?.toUtc().toIso8601String(),
        'terms_version': termsVersion,
        'terms_accepted_at': termsAcceptedAt?.toUtc().toIso8601String(),
        'marketing_consent': marketingConsent,
      };

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.avatarEmoji == avatarEmoji &&
      other.userMode == userMode &&
      other.themeMode == themeMode &&
      _sameMoment(other.ageConfirmedAt, ageConfirmedAt) &&
      other.termsVersion == termsVersion &&
      _sameMoment(other.termsAcceptedAt, termsAcceptedAt) &&
      other.marketingConsent == marketingConsent;

  @override
  int get hashCode => Object.hash(
        displayName,
        avatarEmoji,
        userMode,
        themeMode,
        ageConfirmedAt?.millisecondsSinceEpoch,
        termsVersion,
        termsAcceptedAt?.millisecondsSinceEpoch,
        marketingConsent,
      );

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static bool _sameMoment(DateTime? a, DateTime? b) =>
      a?.millisecondsSinceEpoch == b?.millisecondsSinceEpoch;
}

/// Combines the device profile with the account profile after signing in.
///
/// The account wins (it is what the user set up on other devices), but
/// fields it never had – a fresh account created with defaults – are filled
/// from the device. Consents keep the earliest age confirmation and the
/// newest accepted terms, so signing in never "forgets" a consent.
UserProfile mergeProfiles(UserProfile local, UserProfile? remote) {
  if (remote == null) return local;
  final remoteTermsNewer = remote.termsVersion >= local.termsVersion;
  return UserProfile(
    displayName: remote.displayName == UserProfile.defaultName
        ? local.displayName
        : remote.displayName,
    avatarEmoji: remote.avatarEmoji == UserProfile.defaultAvatar
        ? local.avatarEmoji
        : remote.avatarEmoji,
    userMode: remote.userMode ?? local.userMode,
    themeMode: remote.themeMode ?? local.themeMode,
    ageConfirmedAt: _earliest(remote.ageConfirmedAt, local.ageConfirmedAt),
    termsVersion: remoteTermsNewer ? remote.termsVersion : local.termsVersion,
    termsAcceptedAt:
        remoteTermsNewer ? remote.termsAcceptedAt : local.termsAcceptedAt,
    marketingConsent: remote.marketingConsent,
  );
}

DateTime? _earliest(DateTime? a, DateTime? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.isBefore(b) ? a : b;
}
