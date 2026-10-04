import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../remote/supabase_provider.dart';

/// E-mail + password accounts. Sign-up confirmation and password reset use
/// the links from Supabase's default e-mails: they redirect to
/// [Env.authCallbackUrl], which opens the app, and `supabase_flutter`
/// exchanges the link for a session (PKCE, so the link has to be opened on
/// the phone that asked for it).
class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> userChanges() =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  /// Auth events, including `passwordRecovery` after a reset link opened
  /// the app and errors from expired links.
  Stream<AuthChangeEvent> events() =>
      _auth.onAuthStateChange.map((state) => state.event);

  /// Returns `true` when the account still has to be confirmed by e-mail.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: Env.authCallbackUrl,
      data: {'display_name': displayName},
    ).timeout(_timeout);
    return response.session == null;
  }

  Future<void> resendConfirmation(String email) => _auth
      .resend(
        email: email,
        type: OtpType.signup,
        emailRedirectTo: Env.authCallbackUrl,
      )
      .timeout(_timeout);

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

  /// Sends a reset link; opening it emits `passwordRecovery` (see [events]).
  Future<void> sendPasswordReset(String email) => _auth
      .resetPasswordForEmail(email, redirectTo: Env.authCallbackUrl)
      .timeout(_timeout);

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
    // Links from e-mails put `error` in `code` and `error_code` in
    // `statusCode`, so both are checked.
    final known = [error.code, error.statusCode]
        .map(_authCodeMessage)
        .nonNulls
        .firstOrNull;
    if (known != null) return known;
    // PKCE: the link was opened on a different phone (or after reinstall).
    if (error is AuthPKCEGrantCodeExchangeError ||
        error.message.contains('Code verifier')) {
      return _authCodeMessage('flow_state_not_found')!;
    }
    return 'Nie udało się: ${error.message}';
  }
  if (error is PostgrestException) {
    return 'Błąd bazy danych: ${error.message}';
  }
  return 'Coś poszło nie tak. Spróbuj ponownie.';
}

String? _authCodeMessage(String? code) => switch (code) {
      'invalid_credentials' => 'Nieprawidłowy e-mail lub hasło.',
      'user_already_exists' ||
      'email_exists' =>
        'Konto z tym adresem już istnieje – zaloguj się.',
      'email_not_confirmed' =>
        'Najpierw potwierdź adres e-mail linkiem z wiadomości.',
      'otp_expired' => 'Link jest nieprawidłowy albo wygasł. Wyślij nowy.',
      'flow_state_not_found' ||
      'flow_state_expired' ||
      'bad_code_verifier' =>
        'Otwórz link na tym telefonie, na którym wysłano prośbę, '
            'i spróbuj ponownie.',
      'weak_password' => 'Hasło jest za słabe – użyj co najmniej 8 znaków.',
      'same_password' => 'Nowe hasło musi być inne niż obecne.',
      'email_address_invalid' => 'Ten adres e-mail jest nieprawidłowy.',
      'over_email_send_rate_limit' ||
      'over_request_rate_limit' =>
        'Za dużo prób w krótkim czasie. Spróbuj za kilka minut.',
      'signup_disabled' => 'Rejestracja jest chwilowo wyłączona.',
      _ => null,
    };
