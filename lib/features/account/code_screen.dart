import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_repository.dart';
import 'auth_screen.dart';
import 'validators.dart';

/// Second step of sign-up and password reset: the code from the e-mail.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({
    super.key,
    required this.email,
    this.recovery = false,
    this.next,
  });

  final String email;

  /// `true` for a password reset (asks for a new password too).
  final bool recovery;
  final String? next;

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  static const int _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _password.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = _code.text.trim();
      if (widget.recovery) {
        await repository.resetPassword(
          email: widget.email,
          code: code,
          newPassword: _password.text,
        );
      } else {
        await repository.verifySignupCode(email: widget.email, code: code);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.recovery
                ? 'Hasło zmienione. Jesteś zalogowany.'
                : 'Konto potwierdzone. Witaj w JakWypiję!',
          ),
        ),
      );
      leaveAuthFlow(context, widget.next);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  Future<void> _resend() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    try {
      if (widget.recovery) {
        await repository.sendPasswordReset(widget.email);
      } else {
        await repository.resendSignupCode(widget.email);
      }
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wysłaliśmy nowy kod na ${widget.email}')),
      );
    } on Exception catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recovery ? 'Nowe hasło' : 'Potwierdź e-mail'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Wpisz kod, który wysłaliśmy na',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 10,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.code,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 8,
              ),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.recovery) ...[
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                label: 'Nowe hasło (min. ${Validators.minPasswordLength} '
                    'znaków)',
              ),
            ],
            if (_error != null) AuthErrorText(_error!),
            const SizedBox(height: 16),
            AuthSubmitButton(
              busy: _busy,
              label: widget.recovery ? 'Ustaw hasło' : 'Potwierdź',
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _secondsLeft > 0 ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? 'Wyślij ponownie za $_secondsLeft s'
                    : 'Wyślij kod ponownie',
              ),
            ),
            Text(
              'Nie widzisz wiadomości? Sprawdź folder spam.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
