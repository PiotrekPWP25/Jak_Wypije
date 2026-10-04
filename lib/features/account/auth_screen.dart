import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/auth_repository.dart';
import '../../widgets/bar_info.dart';
import '../profile/profile_providers.dart';
import 'account_providers.dart';
import 'validators.dart';

/// Where to go after signing in, e.g. `/start` from onboarding.
String _safeNext(String? next) =>
    next != null && next.startsWith('/') ? next : '/settings';

void leaveAuthFlow(BuildContext context, String? next) {
  context.go(_safeNext(next));
}

/// Sign in / create an account with e-mail and password.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, this.signUp = false, this.next});

  final bool signUp;
  final String? next;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: signUp ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Konto'),
          leading: IconButton(
            tooltip: 'Zamknij',
            icon: const Icon(Icons.close),
            onPressed: () =>
                context.canPop() ? context.pop() : leaveAuthFlow(context, next),
          ),
          bottom: const TabBar(
            tabs: [Tab(text: 'Zaloguj się'), Tab(text: 'Załóż konto')],
          ),
        ),
        body: TabBarView(
          children: [
            _SignInForm(next: next),
            _SignUpForm(next: next),
          ],
        ),
      ),
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({this.next});

  final String? next;

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.signIn(email: email, password: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zalogowano. Profil się synchronizuje.')),
      );
      leaveAuthFlow(context, widget.next);
    } on AuthException catch (error) {
      if (error.code == 'email_not_confirmed') {
        // Send a fresh link and let the user finish the sign-up.
        try {
          await repository.resendConfirmation(email);
        } on Exception {
          // The check-email screen has its own "send again".
        }
        if (mounted) _openCheckEmail(email);
        return;
      }
      _fail(error);
    } on Exception catch (error) {
      _fail(error);
    }
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = authErrorMessage(error);
    });
  }

  void _openCheckEmail(String email, {bool recovery = false}) {
    setState(() => _busy = false);
    context.push(
      Uri(
        path: '/auth/check-email',
        queryParameters: {
          'email': email,
          'type': recovery ? 'recovery' : 'signup',
          if (widget.next != null) 'next': widget.next,
        },
      ).toString(),
    );
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetEmailDialog(initial: _email.text.trim()),
    );
    if (email == null) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.sendPasswordReset(email);
      if (mounted) _openCheckEmail(email, recovery: true);
    } on Exception catch (error) {
      _fail(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: LogoMark(size: 72)),
          const SizedBox(height: 16),
          Text(
            'Zaloguj się, żeby zachować profil, tryb i zgody na każdym '
            'telefonie.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _EmailField(controller: _email),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            label: 'Hasło',
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _forgotPassword,
              child: const Text('Nie pamiętam hasła'),
            ),
          ),
          if (_error != null) AuthErrorText(_error!),
          const SizedBox(height: 8),
          AuthSubmitButton(
            busy: _busy,
            label: 'Zaloguj się',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm({this.next});

  final String? next;

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _name = TextEditingController(
    text: ref.read(userNameProvider) == 'Ty' ? '' : ref.read(userNameProvider),
  );
  bool _adult = false;
  bool _terms = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final consentsNeeded = needsConsents(ref.read(profileProvider));
    final formValid = _formKey.currentState!.validate();
    if (consentsNeeded && !(_adult && _terms)) {
      setState(() => _error = 'Zaznacz oświadczenie o wieku i akceptację '
          'Regulaminu.');
      return;
    }
    if (!formValid) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final email = _email.text.trim();
    final name = _name.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (consentsNeeded) {
        await ref.read(profileProvider.notifier).acceptAgeAndTerms();
      }
      await ref.read(userNameProvider.notifier).rename(name);
      final needsCode = await repository.signUp(
        email: email,
        password: _password.text,
        displayName: name,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (needsCode) {
        context.push(
          Uri(
            path: '/auth/check-email',
            queryParameters: {
              'email': email,
              'type': 'signup',
              if (widget.next != null) 'next': widget.next,
            },
          ).toString(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto założone. Witaj!')),
        );
        leaveAuthFlow(context, widget.next);
      }
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
    final consentsNeeded = needsConsents(ref.watch(profileProvider));
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _name,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.nickname],
            validator: Validators.displayName,
            decoration: const InputDecoration(
              labelText: 'Imię lub pseudonim',
              helperText: 'Widzą je znajomi w lidze',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          _EmailField(controller: _email),
          const SizedBox(height: 12),
          PasswordField(
            controller: _password,
            label: 'Hasło (min. ${Validators.minPasswordLength} znaków)',
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          if (consentsNeeded) ...[
            CheckboxListTile(
              value: _adult,
              onChanged: (value) => setState(() => _adult = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Mam ukończone 18 lat'),
            ),
            CheckboxListTile(
              value: _terms,
              onChanged: (value) => setState(() => _terms = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Akceptuję Regulamin i zapoznałem/am się z Polityką '
                'prywatności',
              ),
            ),
          ],
          const LegalLinks(),
          if (_error != null) AuthErrorText(_error!),
          const SizedBox(height: 8),
          AuthSubmitButton(
            busy: _busy,
            label: 'Załóż konto',
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Text(
            'Wyślemy link potwierdzający na podany adres – otwórz go na tym '
            'telefonie.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Links to the Terms and Privacy Policy screens.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.push('/legal/terms'),
          child: const Text('Regulamin'),
        ),
        TextButton(
          onPressed: () => context.push('/legal/privacy'),
          child: const Text('Polityka prywatności'),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      validator: Validators.email,
      decoration: const InputDecoration(
        labelText: 'E-mail',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.mail_outline),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.autofillHints = const [AutofillHints.newPassword],
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final List<String> autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      validator: Validators.password,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Pokaż hasło' : 'Ukryj hasło',
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      child: busy
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(label),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }
}

class _ResetEmailDialog extends StatefulWidget {
  const _ResetEmailDialog({required this.initial});

  final String initial;

  @override
  State<_ResetEmailDialog> createState() => _ResetEmailDialogState();
}

class _ResetEmailDialogState extends State<_ResetEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset hasła'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wyślemy link, którym ustawisz nowe hasło.'),
            const SizedBox(height: 16),
            _EmailField(controller: _controller),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Wyślij link')),
      ],
    );
  }
}
