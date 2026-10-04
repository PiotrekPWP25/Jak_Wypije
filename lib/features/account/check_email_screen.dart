import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/auth_repository.dart';
import 'auth_screen.dart';

/// After sign-up or a password-reset request: open the link from the e-mail
/// on this phone. A confirmation link signs the user in (this screen then
/// leaves by itself); a reset link opens the "new password" screen.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({
    super.key,
    required this.email,
    this.recovery = false,
    this.next,
  });

  final String email;

  /// `true` for a password reset, `false` for a sign-up confirmation.
  final bool recovery;
  final String? next;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  static const int _resendSeconds = 60;

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _resend() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() => _error = null);
    try {
      if (widget.recovery) {
        await repository.sendPasswordReset(widget.email);
      } else {
        await repository.resendConfirmation(widget.email);
      }
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wysłaliśmy nowy link na ${widget.email}')),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The confirmation link opened the app and signed the user in.
    ref.listen<User?>(authUserProvider, (previous, user) {
      if (widget.recovery || user == null || previous != null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konto potwierdzone. Witaj!')),
      );
      leaveAuthFlow(context, widget.next);
    });
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recovery ? 'Reset hasła' : 'Potwierdź e-mail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            'Sprawdź skrzynkę',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Wysłaliśmy link na',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.recovery
                    ? 'Otwórz link na tym telefonie – aplikacja pokaże ekran '
                        'ustawienia nowego hasła.'
                    : 'Otwórz link na tym telefonie – aplikacja zaloguje Cię '
                        'automatycznie. Jeśli otworzysz go na komputerze, '
                        'konto też zostanie potwierdzone: wróć wtedy tutaj '
                        'i zaloguj się.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          if (_error != null) AuthErrorText(_error!),
          const SizedBox(height: 16),
          if (!widget.recovery)
            FilledButton(
              onPressed: () => context.go(
                Uri(
                  path: '/auth',
                  queryParameters: {
                    if (widget.next != null) 'next': widget.next,
                  },
                ).toString(),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Potwierdziłem – zaloguj się'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _secondsLeft > 0 ? null : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'Wyślij ponownie za $_secondsLeft s'
                  : 'Wyślij link ponownie',
            ),
          ),
          Text(
            'Nie widzisz wiadomości? Sprawdź folder spam. Nadawca: Supabase '
            'Auth.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
