import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/bar_info.dart';
import 'user_mode.dart';

/// First-run choice: tourist or local. Tailors the Start screen.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    UserMode mode,
  ) async {
    await ref.read(userModeProvider.notifier).set(mode);
    if (context.mounted) context.go('/start');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
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
              'Odkrywaj miasto pieszo: atrakcje, ukryte perełki i bary poza '
              'tłokiem – z bezpiecznym powrotem do domu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text('Jak korzystasz z miasta?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ModeCard(
              emoji: '🧳',
              title: UserMode.tourist.label,
              description: 'Gotowe trasy z zabytkami i barami, must-see w '
                  'pobliżu i Paszport Krakowa do zebrania.',
              color: AppColors.amber,
              onTap: () => _choose(context, ref, UserMode.tourist),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              emoji: '🏠',
              title: UserMode.local.label,
              description: 'Wyzwania tygodnia, wydarzenia, happy hours, nowe '
                  'miejsca i dzielnice do odkrycia.',
              color: AppColors.green,
              onTap: () => _choose(context, ref, UserMode.local),
            ),
            const SizedBox(height: 16),
            Text(
              'Możesz to zmienić w każdej chwili w Profilu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
