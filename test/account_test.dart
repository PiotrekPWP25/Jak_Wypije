import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jak_wypije/data/auth/auth_repository.dart';
import 'package:jak_wypije/data/local/local_storage.dart';
import 'package:jak_wypije/data/models/user_profile.dart';
import 'package:jak_wypije/features/account/account_providers.dart';
import 'package:jak_wypije/features/account/validators.dart';
import 'package:jak_wypije/features/onboarding/onboarding_screen.dart';
import 'package:jak_wypije/features/settings/legal_screen.dart';
import 'package:jak_wypije/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<ProviderContainer> _container([
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<Widget> _app(Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: home),
  );
}

void main() {
  final confirmed = DateTime.utc(2026, 10, 4, 12);

  group('UserProfile', () {
    test('round-trips through JSON with snake_case keys', () {
      final profile = UserProfile(
        displayName: 'Ola',
        avatarEmoji: '🧭',
        userMode: 'local',
        themeMode: 'dark',
        ageConfirmedAt: confirmed,
        termsVersion: 1,
        termsAcceptedAt: confirmed,
        marketingConsent: true,
      );
      final json = profile.toJson();
      expect(json['display_name'], 'Ola');
      expect(json['age_confirmed_at'], '2026-10-04T12:00:00.000Z');
      expect(UserProfile.fromJson(json), profile);
    });

    test('fills defaults for missing or empty fields', () {
      final profile = UserProfile.fromJson({
        'id': 'uuid',
        'display_name': '  ',
        'created_at': '2026-10-04T12:00:00Z',
      });
      expect(profile.displayName, UserProfile.defaultName);
      expect(profile.avatarEmoji, UserProfile.defaultAvatar);
      expect(profile.userMode, isNull);
      expect(profile.isAgeConfirmed, isFalse);
      expect(needsOnboarding(profile), isTrue);
    });

    test('account wins on merge, empty account fields come from device', () {
      final local = UserProfile(
        displayName: 'Ola',
        avatarEmoji: '🚲',
        userMode: 'tourist',
        themeMode: 'light',
        ageConfirmedAt: confirmed,
        termsVersion: 1,
        termsAcceptedAt: confirmed,
      );
      // Fresh account: only the default row created by the SQL trigger.
      const fresh = UserProfile(displayName: 'Ola');
      expect(mergeProfiles(local, fresh), local);

      final remote = UserProfile(
        displayName: 'Aleksandra',
        avatarEmoji: '🦉',
        userMode: 'local',
        ageConfirmedAt: confirmed.subtract(const Duration(days: 30)),
        marketingConsent: true,
      );
      final merged = mergeProfiles(local, remote);
      expect(merged.displayName, 'Aleksandra');
      expect(merged.avatarEmoji, '🦉');
      expect(merged.userMode, 'local');
      expect(merged.themeMode, 'light');
      expect(merged.ageConfirmedAt, remote.ageConfirmedAt);
      // Consent accepted on this device is never lost.
      expect(merged.termsVersion, 1);
      expect(merged.marketingConsent, isTrue);
      expect(mergeProfiles(local, null), local);
    });
  });

  group('LocalStorage profile', () {
    test('profile, consents and clearing user data', () async {
      final container = await _container({
        'user_name': 'Kuba',
        'theme_mode': 'dark',
        'check_ins': '[]',
      });
      final storage = container.read(localStorageProvider);
      expect(storage.loadProfile().displayName, 'Kuba');
      expect(storage.loadProfile().themeMode, 'dark');

      await container.read(profileProvider.notifier).acceptAgeAndTerms(
            now: confirmed,
          );
      final profile = container.read(profileProvider);
      expect(profile.ageConfirmedAt, confirmed);
      expect(profile.termsVersion, currentTermsVersion);
      expect(storage.loadProfile(), profile);

      final export = storage.exportUserData();
      expect((export['profile'] as Map)['display_name'], 'Kuba');
      expect(export['checkIns'], isEmpty);

      await storage.clearUserData();
      final cleared = storage.loadProfile();
      expect(cleared.displayName, UserProfile.defaultName);
      expect(cleared.isAgeConfirmed, isFalse);
      // The theme is a device preference and survives.
      expect(cleared.themeMode, 'dark');
    });
  });

  group('validators', () {
    test('e-mail, password, name and code', () {
      expect(Validators.email('ola@example.com'), isNull);
      expect(Validators.email('ola@'), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
      expect(Validators.displayName('   '), isNotNull);
      expect(Validators.displayName('Ola'), isNull);
      expect(Validators.code('123456'), isNull);
      expect(Validators.code('12a456'), isNotNull);
      expect(Validators.code('123'), isNotNull);
    });
  });

  test('auth errors are translated to Polish', () {
    expect(
      authErrorMessage(
        const AuthException('Invalid', code: 'invalid_credentials'),
      ),
      'Nieprawidłowy e-mail lub hasło.',
    );
    expect(
      authErrorMessage(const AuthException('x', code: 'otp_expired')),
      contains('Kod'),
    );
    expect(authErrorMessage(TimeoutException('t')), contains('połączenia'));
    expect(authErrorMessage(StateError('?')), contains('Spróbuj'));
  });

  test('legal Markdown subset is parsed into blocks', () {
    final blocks = parseLegalDoc(
      '# Tytuł\n\n## 1. Część\n\nPierwsza linia\ndruga **ważna**.\n\n'
      '- punkt A\n- punkt B\n',
    );
    expect(blocks.map((b) => b.type), [
      LegalBlockType.heading,
      LegalBlockType.subheading,
      LegalBlockType.paragraph,
      LegalBlockType.bullet,
      LegalBlockType.bullet,
    ]);
    expect(blocks[2].text, 'Pierwsza linia druga ważna.');
  });

  testWidgets('both legal documents are bundled and start with a title',
      (tester) async {
    for (final doc in LegalDoc.values) {
      expect(LegalDoc.byName(doc.name), doc);
      final blocks = parseLegalDoc(await rootBundle.loadString(doc.asset));
      expect(blocks.first.type, LegalBlockType.heading, reason: doc.asset);
      expect(blocks.length, greaterThan(10), reason: doc.asset);
    }
    expect(LegalDoc.byName('unknown'), isNull);
  });

  testWidgets('settings work in demo mode without an account', (tester) async {
    await tester.pumpWidget(await _app(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Konto niedostępne w wersji demo'), findsOneWidget);
    expect(find.text('Turysta'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Polityka prywatności'), 200);
    expect(find.text('Regulamin'), findsOneWidget);
  });

  testWidgets('onboarding requires age and terms before choosing a mode',
      (tester) async {
    await tester.pumpWidget(await _app(const OnboardingScreen()));
    await tester.pumpAndSettle();

    FilledButton next() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Dalej'));
    expect(next().onPressed, isNull);

    await tester.tap(find.text('Mam ukończone 18 lat'));
    await tester.pump();
    expect(next().onPressed, isNull);
    await tester.tap(find.textContaining('Akceptuję Regulamin'));
    await tester.pump();
    expect(next().onPressed, isNotNull);

    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Jak korzystasz z miasta?'), findsOneWidget);
  });

  testWidgets('underage users cannot continue', (tester) async {
    await tester.pumpWidget(await _app(const OnboardingScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nie mam 18 lat'));
    await tester.pumpAndSettle();
    expect(find.text('Wróć, gdy skończysz 18 lat'), findsOneWidget);
    expect(find.text('Jak korzystasz z miasta?'), findsNothing);
  });
}
