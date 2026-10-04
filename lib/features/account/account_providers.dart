import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/user_profile.dart';
import '../onboarding/user_mode.dart';
import '../profile/profile_providers.dart';

/// Bump when the Terms or Privacy Policy change – users accept them again.
const int currentTermsVersion = 1;

/// The whole profile. Name, mode and theme are owned by their own notifiers
/// (rebuilt here when they change); avatar and consents live here.
class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    ref
      ..watch(userNameProvider)
      ..watch(userModeProvider)
      ..watch(themeModeProvider);
    return ref.watch(localStorageProvider).loadProfile();
  }

  Future<void> _save(UserProfile profile) async {
    state = profile;
    await ref.read(localStorageProvider).saveProfile(profile);
  }

  Future<void> setAvatar(String emoji) =>
      _save(state.copyWith(avatarEmoji: emoji));

  /// The user confirmed they are 18+ and accepted the current documents.
  Future<void> acceptAgeAndTerms({DateTime? now}) {
    final at = now ?? DateTime.now();
    return _save(
      state.copyWith(
        ageConfirmedAt: state.ageConfirmedAt ?? at,
        termsVersion: currentTermsVersion,
        termsAcceptedAt: at,
      ),
    );
  }

  Future<void> setMarketingConsent(bool value) =>
      _save(state.copyWith(marketingConsent: value));
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

/// Age gate, current terms and tourist/local choice are required first.
bool needsOnboarding(UserProfile profile) =>
    profile.userMode == null || needsConsents(profile);

bool needsConsents(UserProfile profile) =>
    !profile.isAgeConfirmed || !profile.hasAcceptedTerms(currentTermsVersion);

/// Set when a password-reset link opened the app before the splash finished;
/// the splash then continues to the "new password" screen.
final passwordRecoveryPendingProvider = StateProvider<bool>((ref) => false);
