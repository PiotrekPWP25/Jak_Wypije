import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/name_dialog.dart';
import '../account/account_providers.dart';
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
      builder: (_) => NameDialog(initial: current),
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
    final placesById = ref.watch(placesByIdProvider);
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
          IconButton(
            tooltip: 'Ustawienia',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ProfileHeader(
            name: name,
            avatar: ref.watch(profileProvider).avatarEmoji,
            level: level,
            points: stats.points,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/passport'),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text('Paszport Krakowa · ${stats.districts}/18 dzielnic'),
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
              message: 'Zamelduj się przy atrakcji albo w barze, żeby zdobyć '
                  'pierwsze punkty.',
            )
          else
            for (final checkIn in checkIns.take(30))
              ListTile(
                leading: Text(
                  placesById[checkIn.placeId]?.emoji ?? '📍',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  placesById[checkIn.placeId]?.name ?? 'Nieznane miejsce',
                ),
                subtitle: Text(
                  '${formatDate(checkIn.timestamp)}'
                  '${checkIn.offPeak ? ' · 🌿 poza tłokiem' : ''}'
                  '${checkIn.completedRoute ? ' · 🏁 trasa' : ''}',
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
    required this.avatar,
    required this.level,
    required this.points,
  });

  final String name;
  final String avatar;
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
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.amber,
            child: Text(avatar, style: const TextStyle(fontSize: 32)),
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
      ('Miejsca', '${stats.uniquePlaces}', Icons.place_outlined),
      ('Dzielnice', '${stats.districts}/18', Icons.menu_book_outlined),
      ('Atrakcje', '${stats.landmarks}', Icons.account_balance_outlined),
      ('Km pieszo', '${stats.walkedKm}', Icons.directions_walk),
      ('Poza tłokiem', '${stats.offPeakCheckIns}', Icons.eco_outlined),
      ('Trasy', '${stats.routesCompleted}', Icons.flag_outlined),
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
