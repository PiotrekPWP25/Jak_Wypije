import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/auth_repository.dart';
import 'auth_screen.dart';
import 'validators.dart';

/// Opened by the password-reset link from the e-mail (the link already
/// signed the user in for this purpose).
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
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
      await repository.changePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasło zmienione. Jesteś zalogowany.')),
      );
      context.go('/settings');
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authUserProvider)?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nowe hasło'),
        leading: IconButton(
          tooltip: 'Zamknij',
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/start'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.lock_reset, size: 72),
            const SizedBox(height: 16),
            Text(
              email == null
                  ? 'Ustaw nowe hasło do konta.'
                  : 'Ustaw nowe hasło do konta $email.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PasswordField(
              controller: _password,
              label: 'Nowe hasło (min. ${Validators.minPasswordLength} znaków)',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _repeat,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) =>
                  value == _password.text ? null : 'Hasła się różnią',
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Powtórz hasło',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_error != null) AuthErrorText(_error!),
            const SizedBox(height: 16),
            AuthSubmitButton(
              busy: _busy,
              label: 'Zapisz hasło',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
