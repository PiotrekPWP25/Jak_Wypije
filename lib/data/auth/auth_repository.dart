import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/supabase_provider.dart';

/// E-mail + password accounts. Confirmation and password reset use the
/// 6-digit code from the e-mail (no deep links needed) – the Supabase e-mail
/// templates must contain `{{ .Token }}`, see README.
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> userChanges() =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  /// Returns `true` when the account still has to be confirmed with a code.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    ).timeout(_timeout);
    return response.session == null;
  }

  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) =>
      _auth
          .verifyOTP(email: email, token: code, type: OtpType.signup)
          .timeout(_timeout);

  Future<void> resendSignupCode(String email) =>
      _auth.resend(email: email, type: OtpType.signup).timeout(_timeout);

  Future<void> signIn({required String email, required String password}) =>
      _auth
          .signInWithPassword(email: email, password: password)
          .timeout(_timeout);

  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(_timeout);
    } on Exception {
      // The local session is removed first, so offline sign-out still works.
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email).timeout(_timeout);

  /// Verifies the recovery code (which signs the user in) and sets a new
  /// password.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _auth
        .verifyOTP(email: email, token: code, type: OtpType.recovery)
        .timeout(_timeout);
    await changePassword(newPassword);
  }

  Future<void> changePassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword)).timeout(_timeout);

  /// Deletes the account and its profile (`delete_my_account()` in SQL).
  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_my_account').timeout(_timeout);
    await signOut();
  }
}

/// `null` in demo mode.
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AuthRepository(client);
});

final _authChangesProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  if (repository == null) return Stream.value(null);
  return repository.userChanges();
});

/// Signed-in user, or `null` (signed out or demo mode).
final authUserProvider = Provider<User?>((ref) {
  final changes = ref.watch(_authChangesProvider);
  return changes.hasValue
      ? changes.value
      : ref.watch(authRepositoryProvider)?.currentUser;
});

/// Polish message for errors thrown by [AuthRepository] and the database.
String authErrorMessage(Object error) {
  if (error is TimeoutException || error is AuthRetryableFetchException) {
    return 'Brak połączenia z serwerem. Sprawdź internet i spróbuj ponownie.';
  }
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => 'Nieprawidłowy e-mail lub hasło.',
      'user_already_exists' ||
      'email_exists' =>
        'Konto z tym adresem już istnieje – zaloguj się.',
      'email_not_confirmed' =>
        'Najpierw potwierdź adres e-mail kodem z wiadomości.',
      'otp_expired' => 'Kod jest nieprawidłowy albo wygasł. Wyślij nowy.',
      'weak_password' => 'Hasło jest za słabe – użyj co najmniej 8 znaków.',
      'same_password' => 'Nowe hasło musi być inne niż obecne.',
      'email_address_invalid' => 'Ten adres e-mail jest nieprawidłowy.',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' =>
        'Za dużo prób w krótkim czasie. Spróbuj za kilka minut.',
      'signup_disabled' => 'Rejestracja jest chwilowo wyłączona.',
      _ => 'Nie udało się: ${error.message}',
    };
  }
  if (error is PostgrestException) {
    return 'Błąd bazy danych: ${error.message}';
  }
  return 'Coś poszło nie tak. Spróbuj ponownie.';
}
