import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/auth/auth_repository.dart';
import '../../widgets/bar_info.dart';
import '../account/account_providers.dart';
import '../account/auth_screen.dart';
import 'user_mode.dart';

enum _Step { consents, underage, mode, account }

/// First run: age gate + Terms, tourist or local, then an optional account.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late _Step _step =
      needsConsents(ref.read(profileProvider)) ? _Step.consents : _Step.mode;
  bool _adult = false;
  bool _terms = false;

  bool get _offerAccount =>
      ref.read(authRepositoryProvider) != null &&
      ref.read(authUserProvider) == null;

  void _afterMode() {
    if (_offerAccount) {
      setState(() => _step = _Step.account);
    } else {
      context.go('/start');
    }
  }

  Future<void> _acceptConsents() async {
    await ref.read(profileProvider.notifier).acceptAgeAndTerms();
    if (!mounted) return;
    if (ref.read(userModeProvider) == null) {
      setState(() => _step = _Step.mode);
    } else {
      _afterMode();
    }
  }

  Future<void> _chooseMode(UserMode mode) async {
    await ref.read(userModeProvider.notifier).set(mode);
    if (mounted) _afterMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            _Step.consents => _ConsentsStep(
                key: const ValueKey(_Step.consents),
                adult: _adult,
                terms: _terms,
                onAdult: (value) => setState(() => _adult = value),
                onTerms: (value) => setState(() => _terms = value),
                onContinue: _adult && _terms ? _acceptConsents : null,
                onUnderage: () => setState(() => _step = _Step.underage),
              ),
            _Step.underage => _UnderageStep(
                key: const ValueKey(_Step.underage),
                onBack: () => setState(() => _step = _Step.consents),
              ),
            _Step.mode => _ModeStep(
                key: const ValueKey(_Step.mode),
                onChoose: _chooseMode,
              ),
            _Step.account => const _AccountStep(key: ValueKey(_Step.account)),
          },
        ),
      ),
    );
  }
}

class _ConsentsStep extends StatelessWidget {
  const _ConsentsStep({
    super.key,
    required this.adult,
    required this.terms,
    required this.onAdult,
    required this.onTerms,
    required this.onContinue,
    required this.onUnderage,
  });

  final bool adult;
  final bool terms;
  final ValueChanged<bool> onAdult;
  final ValueChanged<bool> onTerms;
  final VoidCallback? onContinue;
  final VoidCallback onUnderage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: LogoMark(size: 96)),
        const SizedBox(height: 16),
        Text(
          'Witaj w JakWypiję!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Aplikacja pokazuje lokale i ceny napojów, dlatego jest tylko dla '
          'osób pełnoletnich.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                CheckboxListTile(
                  value: adult,
                  onChanged: (value) => onAdult(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Mam ukończone 18 lat'),
                ),
                CheckboxListTile(
                  value: terms,
                  onChanged: (value) => onTerms(value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Akceptuję Regulamin i zapoznałem/am się z Polityką '
                    'prywatności',
                  ),
                ),
                const LegalLinks(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Dalej'),
        ),
        TextButton(
          onPressed: onUnderage,
          child: const Text('Nie mam 18 lat'),
        ),
      ],
    );
  }
}

class _UnderageStep extends StatelessWidget {
  const _UnderageStep({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🙂', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Wróć, gdy skończysz 18 lat',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'JakWypiję jest przeznaczona wyłącznie dla osób pełnoletnich.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextButton(onPressed: onBack, child: const Text('Wróć')),
          ],
        ),
      ),
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({super.key, required this.onChoose});

  final ValueChanged<UserMode> onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: LogoMark(size: 96)),
        const SizedBox(height: 16),
        Text(
          'Odkrywaj miasto pieszo',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Atrakcje, ukryte perełki i bary poza tłokiem – z bezpiecznym '
          'powrotem do domu.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Text('Jak korzystasz z miasta?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _ModeCard(
          emoji: '🧳',
          title: UserMode.tourist.label,
          description: 'Gotowe trasy z zabytkami i barami, must-see w '
              'pobliżu i Paszport Krakowa do zebrania.',
          color: AppColors.amber,
          onTap: () => onChoose(UserMode.tourist),
        ),
        const SizedBox(height: 12),
        _ModeCard(
          emoji: '🏠',
          title: UserMode.local.label,
          description: 'Wyzwania tygodnia, wydarzenia, happy hours, nowe '
              'miejsca i dzielnice do odkrycia.',
          color: AppColors.green,
          onTap: () => onChoose(UserMode.local),
        ),
        const SizedBox(height: 16),
        Text(
          'Możesz to zmienić w każdej chwili w Ustawieniach.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AccountStep extends StatelessWidget {
  const _AccountStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.cloud_sync_outlined, size: 72, color: AppColors.green),
        const SizedBox(height: 16),
        Text(
          'Zachowaj profil na każdym telefonie',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Konto zapisuje Twoje imię, tryb, motyw i zgody. Bez konta '
          'wszystko zostaje tylko na tym urządzeniu.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/auth?signup=1&next=/start'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Załóż konto'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go('/auth?next=/start'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Mam już konto'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/start'),
          child: const Text('Pomiń – dane zostaną na tym telefonie'),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withAlpha(50),
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
