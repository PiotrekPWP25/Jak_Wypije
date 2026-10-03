import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/platform/external_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/user_profile.dart';
import '../../widgets/name_dialog.dart';
import '../../widgets/section_header.dart';
import '../account/account_providers.dart';
import '../account/auth_screen.dart';
import '../account/profile_sync.dart';
import '../onboarding/user_mode.dart';
import '../profile/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileSyncProvider, (previous, next) {
      if (next == ProfileSyncStatus.pending &&
          previous != ProfileSyncStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.label)),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: const [
          SectionHeader(title: 'Konto'),
          _AccountSection(),
          SectionHeader(title: 'Profil'),
          _ProfileSection(),
          SectionHeader(title: 'Wygląd'),
          _AppearanceSection(),
          SectionHeader(title: 'Prywatność'),
          _PrivacySection(),
          SectionHeader(title: 'Odpowiedzialnie'),
          _ResponsibleSection(),
          SectionHeader(title: 'Informacje'),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _changePassword(
    BuildContext context,
    AuthRepository repository,
  ) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _NewPasswordDialog(),
    );
    if (password == null || !context.mounted) return;
    await _run(
      context,
      () => repository.changePassword(password),
      success: 'Hasło zmienione.',
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
    AuthRepository repository,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      repository.deleteAccount,
      success: 'Konto i profil na serwerze zostały usunięte.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(profileSyncProvider);
    final repository = ref.watch(authRepositoryProvider);
    final user = ref.watch(authUserProvider);
    final theme = Theme.of(context);

    if (repository == null) {
      return ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: const Text('Konto niedostępne w wersji demo'),
        subtitle: const Text(
          'Dane zostają tylko na tym telefonie. Konta włączysz, uruchamiając '
          'aplikację z kluczami Supabase (README).',
        ),
      );
    }
    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: const Text('Zaloguj się lub załóż konto'),
        subtitle: Text(status.label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/auth'),
      );
    }
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text(user.email ?? 'Zalogowano'),
          subtitle: Text(status.label),
          trailing: status == ProfileSyncStatus.pending
              ? IconButton(
                  tooltip: 'Synchronizuj teraz',
                  icon: const Icon(Icons.sync),
                  onPressed: () =>
                      ref.read(profileSyncProvider.notifier).pullAndMerge(),
                )
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.password),
          title: const Text('Zmień hasło'),
          onTap: () => _changePassword(context, repository),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Wyloguj się'),
          subtitle: const Text('Profil zostaje na tym telefonie'),
          onTap: () => _run(
            context,
            repository.signOut,
            success: 'Wylogowano.',
          ),
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: AppColors.coral),
          title: Text(
            'Usuń konto',
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.coral),
          ),
          subtitle: const Text('Trwale usuwa konto i profil z serwera'),
          onTap: () => _deleteAccount(context, repository),
        ),
      ],
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider);
    final profile = ref.watch(profileProvider);
    final mode = ref.watch(userModeProvider) ?? UserMode.tourist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.amber,
            child: Text(profile.avatarEmoji),
          ),
          title: Text(name),
          subtitle: const Text('Imię widoczne na Starcie i w lidze'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (_) => NameDialog(initial: name),
            );
            if (result != null) {
              await ref.read(userNameProvider.notifier).rename(result);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final emoji in UserProfile.avatars)
                ChoiceChip(
                  label: Text(emoji, style: const TextStyle(fontSize: 20)),
                  showCheckmark: false,
                  selected: profile.avatarEmoji == emoji,
                  onSelected: (_) =>
                      ref.read(profileProvider.notifier).setAvatar(emoji),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<UserMode>(
            segments: const [
              ButtonSegment(
                value: UserMode.tourist,
                icon: Icon(Icons.luggage_outlined),
                label: Text('Turysta'),
              ),
              ButtonSegment(
                value: UserMode.local,
                icon: Icon(Icons.home_outlined),
                label: Text('Mieszkaniec'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) =>
                ref.read(userModeProvider.notifier).set(selection.first),
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('Jasny'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('Ciemny'),
          ),
        ],
        selected: {ref.watch(themeModeProvider)},
        onSelectionChanged: (selection) =>
            ref.read(themeModeProvider.notifier).set(selection.first),
      ),
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authUserProvider);
    final data = {
      'app': 'JakWypiję ${Env.appVersion}',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      if (user != null) 'account': {'id': user.id, 'email': user.email},
      ...ref.read(localStorageProvider).exportUserData(),
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Twoje dane (JSON) skopiowano do schowka.'),
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić dane na tym telefonie?'),
        content: const Text(
          'Usuniemy meldunki, plan trasy, oceny, profil i zgody zapisane na '
          'tym urządzeniu oraz wylogujemy Cię. Konto na serwerze zostaje.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider)?.signOut();
    // The splash clears the data once the tabs are gone, so no screen
    // rebuilds with an empty profile in the meantime.
    if (context.mounted) context.go('/splash?reset=1');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final hasAccounts = ref.watch(authRepositoryProvider) != null;
    return Column(
      children: [
        if (hasAccounts)
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined),
            title: const Text('Wydarzenia i nowości e-mailem'),
            subtitle: const Text('Zgoda dobrowolna, możesz ją wycofać'),
            value: profile.marketingConsent,
            onChanged: (value) =>
                ref.read(profileProvider.notifier).setMarketingConsent(value),
          ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Eksportuj moje dane'),
          subtitle: const Text('Kopia profilu, meldunków i ocen (JSON)'),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined),
          title: const Text('Wyczyść dane na tym urządzeniu'),
          onTap: () => _clear(context, ref),
        ),
        const ListTile(
          leading: Icon(Icons.location_on_outlined),
          title: Text('Lokalizacja'),
          subtitle: Text(
            'Używana tylko na telefonie – do odległości i meldunku przy '
            'atrakcji. Nie wysyłamy jej na serwer. Dostęp zmienisz w '
            'ustawieniach systemu.',
          ),
        ),
      ],
    );
  }
}

class _ResponsibleSection extends ConsumerWidget {
  const _ResponsibleSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmedAt = ref.watch(profileProvider).ageConfirmedAt;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Aplikacja dla osób 18+'),
          subtitle: Text(
            confirmedAt == null
                ? 'Pełnoletność niepotwierdzona'
                : 'Pełnoletność potwierdzona ${formatDate(confirmedAt.toLocal())}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.directions_bus_outlined),
          title: const Text('Bezpieczny powrót'),
          subtitle: const Text('Nocne MPK z końca trasy. Nie prowadź po '
              'alkoholu.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/safe-return'),
        ),
        ListTile(
          leading: const Icon(Icons.support_outlined),
          title: const Text('Pomoc w uzależnieniach'),
          subtitle: const Text(
            'Krajowe Centrum Przeciwdziałania Uzależnieniom · kcpu.gov.pl',
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            final url = Uri.https('www.kcpu.gov.pl');
            final opened = await ExternalLauncher.openUrl(url);
            if (opened) return;
            await Clipboard.setData(ClipboardData(text: url.toString()));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skopiowano adres strony.')),
            );
          },
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Regulamin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/legal/terms'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Polityka prywatności'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/legal/privacy'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Licencje open source'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'JakWypiję',
            applicationVersion: Env.appVersion,
            applicationLegalese: 'Mapy © OpenStreetMap contributors',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.map_outlined),
          title: Text('Źródła danych'),
          subtitle: Text(
            'Mapy © OpenStreetMap contributors (ODbL). Nazwy barów są '
            'fikcyjne, tłok, MPK i wydarzenia to dane przykładowe (demo).',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Wersja'),
          subtitle: Text('JakWypiję ${Env.appVersion}'),
        ),
      ],
    );
  }
}

/// Runs an account action with a SnackBar for success or a Polish error.
Future<void> _run(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(success)));
  } on Exception catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
  }
}

class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog();

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nowe hasło'),
      content: Form(
        key: _formKey,
        child: PasswordField(controller: _controller, label: 'Nowe hasło'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: const Text('Zmień'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const String _confirmWord = 'USUŃ';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _controller.text.trim().toUpperCase() == _confirmWord;
    return AlertDialog(
      title: const Text('Usunąć konto?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konto i profil zostaną trwale usunięte z serwera. Tej operacji '
            'nie można cofnąć. Dane na tym telefonie zostają, dopóki ich nie '
            'wyczyścisz.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Wpisz $_confirmWord, aby potwierdzić',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Usuń konto'),
        ),
      ],
    );
  }
}
