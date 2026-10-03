import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bar.dart';
import '../../data/models/city_zone.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../widgets/bar_info.dart';
import '../../widgets/section_header.dart';
import '../barobranie/plan_calculator.dart';
import '../barobranie/planner_controller.dart';
import '../bars/bars_providers.dart';
import '../friends/leagues.dart';
import '../profile/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Header(),
            _EveningCard(bars: bars),
            const _QuickActions(),
            const _CityNowCard(),
            const SectionHeader(title: 'Ukryte perełki dla Ciebie'),
            _GemsCarousel(bars: bars),
            const _LeagueCard(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Dzień dobry';
    if (hour >= 12 && hour < 18) return 'Cześć';
    return 'Dobry wieczór';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const LogoMark(size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $name!',
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  'Gdzie dziś wypijesz?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Tryb jasny' : 'Tryb ciemny',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_outlined),
          ),
          IconButton(
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
            icon: const CircleAvatar(
              backgroundColor: AppColors.amber,
              child: Text('🍺'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EveningCard extends ConsumerWidget {
  const _EveningCard({required this.bars});

  final List<Bar> bars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(plannerProvider);
    final zones = ref.watch(zonesByIdProvider);
    final stops = resolveStops(plan, bars);
    final summary = calculatePlan(plan, stops, zones: zones);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.amber, Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.brown, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.brown),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Twój wieczór',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppColors.brown),
              ),
              const SizedBox(height: 6),
              if (stops.isEmpty)
                const Text(
                  'Nie masz jeszcze trasy. Wybierz bary, a my ułożymy '
                  'Barobranie, policzymy spacer, budżet i powrót do domu.',
                )
              else ...[
                Text(
                  '${stops.length} '
                  '${pluralize(stops.length, 'bar', 'bary', 'barów')} · '
                  '${formatClock(plan.startMinutes)}–'
                  '${formatClock(summary.endMinutes)} · '
                  '${summary.totalCost.label}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  stops.map((bar) => bar.emoji).join('  →  '),
                  style: const TextStyle(fontSize: 22),
                ),
                if (summary.warningCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ ${summary.warningCount} '
                    '${pluralize(summary.warningCount, 'uwaga', 'uwagi', 'uwag')} '
                    'do trasy',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brown,
                      foregroundColor: AppColors.amber,
                    ),
                    onPressed: () => context.go(
                      stops.isEmpty ? '/bars' : '/barobranie',
                    ),
                    icon: Icon(stops.isEmpty ? Icons.add : Icons.route),
                    label: Text(
                      stops.isEmpty ? 'Zaplanuj Barobranie' : 'Otwórz trasę',
                    ),
                  ),
                  if (stops.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brown,
                      ),
                      onPressed: () => context.push('/safe-return'),
                      child: const Text('Powrót do domu'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.qr_code_scanner,
                label: 'Melduj się',
                color: AppColors.amber,
                onTap: () => context.push('/checkin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.directions_bus,
                label: 'Bezpieczny powrót',
                color: AppColors.night,
                onTap: () => context.push('/safe-return'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.near_me,
                label: 'Bary w pobliżu',
                color: AppColors.green,
                onTap: () {
                  ref
                      .read(distanceReferenceProvider.notifier)
                      .set(DistanceReference.me);
                  context.go('/bars');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(45),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smart City: live (or forecast) crowd levels and a nudge towards calmer
/// districts.
class _CityNowCard extends ConsumerWidget {
  const _CityNowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final zones = ref.watch(zonesProvider).valueOrNull ?? const <CityZone>[];
    final clock = ref.watch(cityClockProvider);
    if (zones.isEmpty) return const SizedBox.shrink();

    final sorted = [...zones]..sort(
        (a, b) => b.crowdAt(clock.minutes).compareTo(a.crowdAt(clock.minutes)));
    final busiest = sorted.first;
    final calmest = sorted.last;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_city, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Teraz w mieście',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    clock.isForecast
                        ? 'prognoza na ${formatClock(clock.minutes)}'
                        : 'na żywo · ${formatClock(clock.minutes)}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final zone in sorted.take(5))
                _ZoneCrowdRow(zone: zone, minutes: clock.minutes),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${busiest.name}: tłoczno. Spokojniej jest w okolicy: '
                  '${calmest.name}. Za meldunek poza tłokiem +10 pkt.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneCrowdRow extends StatelessWidget {
  const _ZoneCrowdRow({required this.zone, required this.minutes});

  final CityZone zone;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final crowd = zone.crowdAt(minutes);
    final level = crowdLevelOf(crowd);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Row(
              children: [
                Flexible(
                  child: Text(zone.name, overflow: TextOverflow.ellipsis),
                ),
                if (zone.quietZone) ...[
                  const SizedBox(width: 4),
                  const Tooltip(
                    message: 'Strefa ciszy nocnej po 22:00',
                    child: Icon(
                      Icons.bedtime,
                      size: 14,
                      color: AppColors.night,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: crowd / 100,
                minHeight: 8,
                color: level.color,
                backgroundColor: level.color.withAlpha(40),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 56, child: _CrowdText(level: level)),
        ],
      ),
    );
  }
}

class _CrowdText extends StatelessWidget {
  const _CrowdText({required this.level});

  final CrowdLevel level;

  @override
  Widget build(BuildContext context) {
    return Text(
      level.label,
      textAlign: TextAlign.end,
      style: TextStyle(color: level.color, fontWeight: FontWeight.w800),
    );
  }
}

class _GemsCarousel extends ConsumerWidget {
  const _GemsCarousel({required this.bars});

  final List<Bar> bars;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(barListingsProvider).valueOrNull ?? const [];
    final gems = listings.where((l) => l.bar.isHiddenGem).toList()
      ..sort((a, b) => (b.friendsRating ?? 0).compareTo(a.friendsRating ?? 0));
    if (gems.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: gems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final listing = gems[index];
          final bar = listing.bar;
          return SizedBox(
            width: 150,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/bar/${bar.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bar.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        bar.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        bar.district,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      FriendsScoreBadge(
                        rating: listing.friendsRating,
                        count: listing.friendsRatingCount,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LeagueCard extends ConsumerWidget {
  const _LeagueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final table = ref.watch(leagueTableProvider);
    final xp = ref.watch(myWeeklyXpProvider);
    final streak = ref.watch(myStreakWeeksProvider);
    final rank = table.myRank;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/friends'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, size: 44, color: myLeague.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(myLeague.label, style: theme.textTheme.titleMedium),
                      Text(
                        '${rank == null ? '' : '#$rank · '}$xp XP w tym tygodniu',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 22)),
                    Text(
                      '$streak ${pluralize(streak, 'tydz.', 'tyg.', 'tyg.')}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
