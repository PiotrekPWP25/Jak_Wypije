import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bar.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../checkin/check_in_controller.dart';
import '../friends/trophies.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (result == null) return;
    await ref.read(userNameProvider.notifier).rename(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider);
    final stats = ref.watch(profileStatsProvider);
    final level = levelFor(stats.points);
    final trophies = ref.watch(trophiesProvider);
    final checkIns = ref.watch(checkInsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    final barsById = {for (final bar in bars) bar.id: bar};
    int countTier(TrophyTier tier) =>
        trophies.where((trophy) => trophy.tier == tier).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Zmień imię',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editName(context, ref, name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ProfileHeader(name: name, level: level, points: stats.points),
          Padding(
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
              selected: {themeMode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).set(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          _StatsGrid(stats: stats),
          SectionHeader(
            title: 'Pucharki',
            trailing: TextButton(
              onPressed: () => context.go('/friends'),
              child: const Text('Gablota'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final tier in [
                  TrophyTier.gold,
                  TrophyTier.silver,
                  TrophyTier.bronze,
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events, size: 36, color: tier.color),
                        Text(
                          '${countTier(tier)} × ${tier.label}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader(title: 'Historia meldunków'),
          if (checkIns.isEmpty)
            const EmptyState(
              icon: Icons.qr_code_2,
              title: 'Brak meldunków',
              message: 'Zeskanuj kod QR w barze, żeby zdobyć pierwsze punkty.',
            )
          else
            for (final checkIn in checkIns.take(30))
              ListTile(
                leading: Text(
                  barsById[checkIn.barId]?.emoji ?? '🍺',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(barsById[checkIn.barId]?.name ?? 'Nieznany bar'),
                subtitle: Text(
                  '${formatDate(checkIn.timestamp)}'
                  '${checkIn.offPeak ? ' · 🌿 poza tłokiem' : ''}',
                ),
                trailing: Text(
                  '+${checkIn.points} pkt',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.level,
    required this.points,
  });

  final String name;
  final Level level;
  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = level.nextPoints;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.amber,
            child: Text('🍺', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.headlineSmall),
                Text(
                  'Poziom ${level.number} · ${level.title}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: level.progress(points),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next == null
                      ? '$points pkt · maksymalny poziom!'
                      : '$points / $next pkt do kolejnego poziomu',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, String, IconData)>[
      ('Meldunki', '${stats.checkIns}', Icons.qr_code_scanner),
      ('Bary', '${stats.uniqueBars}', Icons.sports_bar),
      ('Dzielnice', '${stats.districts}', Icons.location_city),
      ('Perełki', '${stats.hiddenGems}', Icons.diamond_outlined),
      ('Poza tłokiem', '${stats.offPeakCheckIns}', Icons.eco_outlined),
      ('Powroty', '${stats.safeReturns}', Icons.directions_bus),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, value, icon) in items)
                SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          Icon(icon, color: AppColors.amber),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jak masz na imię?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Zapisz')),
      ],
    );
  }
}
