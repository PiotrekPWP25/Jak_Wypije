import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bar.dart';
import '../../data/models/friend.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/section_header.dart';
import '../profile/profile_providers.dart';
import 'leagues.dart';
import 'reviews_controller.dart';
import 'trophies.dart';
import '../gamification/challenges_card.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = ref.watch(leagueTableProvider);
    final trophies = ref.watch(trophiesProvider);
    final streak = ref.watch(myStreakWeeksProvider);
    final people = ref.watch(friendsProvider).valueOrNull ?? const <Friend>[];
    final friends = people.where((person) => person.isFriend).toList()
      ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
    final reviews =
        ref.watch(allReviewsProvider).valueOrNull ?? const <Review>[];
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    final barsById = {for (final bar in bars) bar.id: bar};
    final friendsById = ref.watch(friendsByIdProvider);
    final myName = ref.watch(userNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Znajomi i ligi')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _LeagueHeader(),
          _StreakBanner(weeks: streak),
          const SectionHeader(title: 'Wyzwania tygodnia'),
          const WeeklyChallengesCard(),
          const SectionHeader(title: 'Tabela tygodnia'),
          _LeagueTableCard(table: table),
          SectionHeader(
            title: 'Gablota pucharków',
            trailing: Text(
              '${trophies.where((t) => t.tier != TrophyTier.none).length}'
              '/${trophies.length}',
            ),
          ),
          _TrophyGrid(trophies: trophies),
          const SectionHeader(title: 'Twoi znajomi'),
          for (final friend in friends) _FriendTile(friend: friend),
          const SectionHeader(title: 'Ostatnie oceny znajomych'),
          for (final review in reviews.where((r) => !r.isMine).take(8))
            Builder(
              builder: (context) {
                final author = resolveAuthor(review, friendsById, myName);
                return ReviewTile(
                  review: review,
                  authorName: author.name,
                  authorEmoji: author.emoji,
                  barName: barsById[review.barId]?.name,
                  onTap: () => context.push('/bar/${review.barId}'),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final left = untilWeekEnds(DateTime.now());
    final days = left.inDays;
    final hours = left.inHours % 24;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final league in League.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Opacity(
                      opacity: league.index <= myLeague.index ? 1.0 : 0.3,
                      child: Icon(
                        Icons.emoji_events,
                        size: league == myLeague ? 60 : 36,
                        color: league.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(myLeague.label, style: theme.textTheme.headlineSmall),
          Text(
            'Top 3 awansuje · koniec za $days '
            '${pluralize(days, 'dzień', 'dni', 'dni')} $hours h',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.amber.withAlpha(45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$weeks ${pluralize(weeks, 'tydzień', 'tygodnie', 'tygodni')} '
                    'z rzędu',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    'Seria liczy tygodnie z choć jednym meldunkiem – '
                    'nie nagradzamy picia codziennie.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueTableCard extends StatelessWidget {
  const _LeagueTableCard({required this.table});

  final LeagueTable table;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < table.entries.length; i++) {
      final zone = table.zoneOf(i);
      final previous = i == 0 ? null : table.zoneOf(i - 1);
      if (zone == LeagueZone.demotion && previous != LeagueZone.demotion) {
        rows.add(
          const _ZoneDivider(
            label: 'Strefa spadku',
            icon: Icons.arrow_downward,
            color: AppColors.coral,
          ),
        );
      }
      rows.add(_LeagueRow(rank: i + 1, entry: table.entries[i], zone: zone));
      if (i == LeagueTable.promotionSlots - 1) {
        rows.add(
          const _ZoneDivider(
            label: 'Strefa awansu',
            icon: Icons.arrow_upward,
            color: AppColors.green,
          ),
        );
      }
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: color)),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: color),
          Text(
            ' $label',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}

class _LeagueRow extends StatelessWidget {
  const _LeagueRow({
    required this.rank,
    required this.entry,
    required this.zone,
  });

  final int rank;
  final LeagueEntry entry;
  final LeagueZone zone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rankColor = switch (zone) {
      LeagueZone.promotion => AppColors.green,
      LeagueZone.demotion => AppColors.coral,
      LeagueZone.safe => theme.colorScheme.onSurfaceVariant,
    };
    return Container(
      color: entry.isMe ? AppColors.amber.withAlpha(50) : null,
      child: ListTile(
        leading: SizedBox(
          width: 64,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(entry.emoji),
              ),
            ],
          ),
        ),
        title: Text(
          entry.isMe ? '${entry.name} (Ty)' : entry.name,
          style: TextStyle(
            fontWeight: entry.isMe ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        subtitle: entry.isFriend ? const Text('Znajomy') : null,
        trailing: Text(
          '${entry.weeklyXp} XP',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TrophyGrid extends StatelessWidget {
  const _TrophyGrid({required this.trophies});

  final List<TrophyProgress> trophies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final trophy in trophies)
                SizedBox(width: width, child: _TrophyCard(trophy: trophy)),
            ],
          );
        },
      ),
    );
  }
}

class _TrophyCard extends StatelessWidget {
  const _TrophyCard({required this.trophy});

  final TrophyProgress trophy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = trophy.tier;
    final tierColor = tier.color ?? theme.colorScheme.outlineVariant;
    final next = trophy.nextThreshold;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              '${trophy.definition.emoji} ${trophy.definition.title}',
            ),
            content: Text(
              '${trophy.definition.description}\n\n'
              'Brąz: ${trophy.definition.thresholds[0]} · '
              'Srebro: ${trophy.definition.thresholds[1]} · '
              'Złoto: ${trophy.definition.thresholds[2]}\n'
              'Twój wynik: ${trophy.value}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 40, color: tierColor),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          trophy.definition.emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tier == TrophyTier.none ? 'Zablokowany' : tier.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tier.color ?? theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                trophy.definition.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: trophy.progressToNext,
                  minHeight: 6,
                  color: next == null ? AppColors.gold : AppColors.amber,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                next == null ? 'Maks!' : '${trophy.value}/$next',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final league = leagueById(friend.leagueId);
    return ListTile(
      leading: CircleAvatar(child: Text(friend.emoji)),
      title: Text(friend.name),
      subtitle: Text(
        '${league.label} · 🔥 ${friend.streakWeeks} tyg. · '
        'ulubiona dzielnica: ${friend.favoriteDistrict}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.emoji_events, color: league.color),
          Text('${friend.weeklyXp} XP'),
        ],
      ),
    );
  }
}
