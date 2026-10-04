import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../friends/leagues.dart';
import 'challenges.dart';
import 'gamification_providers.dart';

/// This week's three rotating challenges.
class WeeklyChallengesCard extends ConsumerWidget {
  const WeeklyChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final challenges = ref.watch(weeklyChallengesProvider);
    final left = untilWeekEnds(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wyzwania tygodnia',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  left.inDays == 0
                      ? 'nowe od jutra'
                      : 'nowe za ${left.inDays} '
                          '${pluralize(left.inDays, 'dzień', 'dni', 'dni')}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final progress in challenges)
              _ChallengeRow(progress: progress),
          ],
        ),
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({required this.progress});

  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final challenge = progress.challenge;
    final done = progress.completed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(challenge.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(challenge.description, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.progress,
                    minHeight: 6,
                    color: done ? AppColors.green : AppColors.amber,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                done
                    ? '✓'
                    : '${progress.value.clamp(0, challenge.target)}'
                        '/${challenge.target}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: done ? AppColors.green : null,
                ),
              ),
              Text(
                '+${challenge.rewardXp} XP',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
