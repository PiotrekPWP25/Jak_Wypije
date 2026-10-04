import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/city_district.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/bar_info.dart';
import '../../widgets/section_header.dart';
import '../barobranie/plan_calculator.dart';
import '../barobranie/planner_controller.dart';
import '../bars/bar_filters.dart';
import '../bars/bars_providers.dart';
import '../events/events_widgets.dart';
import '../friends/leagues.dart';
import '../gamification/challenges_card.dart';
import '../gamification/gamification_providers.dart';
import '../onboarding/user_mode.dart';
import '../../core/utils/geo.dart';
import '../../data/models/user_profile.dart';
import '../account/account_providers.dart';
import '../profile/profile_providers.dart';
import '../trips/trips_widgets.dart';

/// Start screen – sections depend on the tourist / local mode.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(userModeProvider) ?? UserMode.tourist;
    // Most useful first; the crowd overview closes the screen.
    final sections = mode == UserMode.tourist
        ? const <Widget>[
            SectionHeader(title: 'Gotowe trasy'),
            TripsCarousel(preferred: TripAudience.tourist),
            _MustSeeSection(),
            _PassportCard(),
            _GemsSection(),
            _CityNowCard(),
          ]
        : const <Widget>[
            SizedBox(height: 16),
            WeeklyChallengesCard(),
            SectionHeader(title: 'W tym tygodniu'),
            UpcomingEventsCard(),
            _HappyHoursSection(),
            _NewPlacesSection(),
            _UnvisitedDistrictsCard(),
            _LeagueCard(),
            SectionHeader(title: 'Trasy dla mieszkańców'),
            TripsCarousel(preferred: TripAudience.local),
            _CityNowCard(),
          ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const _Header(),
            const _EveningCard(),
            const _QuickActions(),
            ...sections,
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
    final mode = ref.watch(userModeProvider) ?? UserMode.tourist;
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
                  // No "Dobry wieczór, Ty!" before the user sets a name.
                  name == UserProfile.defaultName
                      ? '${_greeting()}!'
                      : '${_greeting()}, $name!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  mode == UserMode.tourist
                      ? 'Co dziś zobaczysz w Krakowie?'
                      : 'Co nowego w Twoim mieście?',
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
            icon: CircleAvatar(
              backgroundColor: AppColors.amber,
              child: Text(ref.watch(profileProvider).avatarEmoji),
            ),
          ),
        ],
      ),
    );
  }
}

class _EveningCard extends ConsumerWidget {
  const _EveningCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(plannerProvider);
    final zones = ref.watch(zonesByIdProvider);
    final stops = resolveStops(plan, ref.watch(placesByIdProvider));
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
                'Twoja trasa',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: AppColors.brown),
              ),
              const SizedBox(height: 6),
              if (stops.isEmpty)
                const Text(
                  'Atrakcje i lokale w jednej trasie. Policzymy spacer, '
                  'budżet i powrót.',
                )
              else ...[
                Text(
                  '${stops.length} '
                  '${pluralize(stops.length, 'przystanek', 'przystanki', 'przystanków')}'
                  ' · ${formatClock(plan.startMinutes)}–'
                  '${formatClock(summary.endMinutes)} · '
                  '${formatDistance(summary.totalWalkMeters)} pieszo',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  stops.map((place) => place.emoji).join('  →  '),
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
                    onPressed: () => context.go('/barobranie'),
                    icon: Icon(stops.isEmpty ? Icons.add : Icons.route),
                    label: Text(
                      stops.isEmpty ? 'Zaplanuj trasę' : 'Otwórz trasę',
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
                onColor: AppColors.brown,
                onTap: () => context.push('/checkin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.menu_book_outlined,
                label: 'Paszport',
                color: AppColors.greenDeep,
                onTap: () => context.push('/passport'),
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
    this.onColor = Colors.white,
  });

  final IconData icon;
  final String label;

  /// Solid circle behind the icon, [onColor] for the icon itself.
  final Color color;
  final Color onColor;
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
                radius: 24,
                backgroundColor: color,
                foregroundColor: onColor,
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

/// "Wszystkie" link to the Bary tab, showing bars or landmarks.
class _SeeAllButton extends ConsumerWidget {
  const _SeeAllButton({required this.landmarks});

  final bool landmarks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        ref.read(showLandmarksProvider.notifier).set(landmarks);
        context.go('/bars');
      },
      child: const Text('Wszystkie'),
    );
  }
}

/// Nearest landmarks from the user in Kraków (or the route's last stop,
/// else Rynek).
class _MustSeeSection extends ConsumerWidget {
  const _MustSeeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(landmarkListingsProvider).valueOrNull ??
        const <LandmarkListing>[];
    if (listings.isEmpty) return const SizedBox.shrink();
    final fromCenter = ref.watch(referencePointProvider).point == krakowCenter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: fromCenter ? 'Must-see od Rynku' : 'Must-see w pobliżu',
          trailing: const _SeeAllButton(landmarks: true),
        ),
        _HorizontalCards(
          children: [
            for (final listing in listings.take(8))
              _MiniCard(
                emoji: listing.landmark.emoji,
                color: AppColors.green,
                chip: formatDistance(listing.distanceMeters),
                title: listing.landmark.name,
                subtitle: listing.landmark.category.label,
                footer: listing.landmark.ticketLabel,
                onTap: () => context.push('/landmark/${listing.landmark.id}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _GemsSection extends ConsumerWidget {
  const _GemsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(barListingsProvider).valueOrNull ?? const [];
    final gems = listings.where((l) => l.bar.isHiddenGem).toList()
      ..sort((a, b) => (b.friendsRating ?? 0).compareTo(a.friendsRating ?? 0));
    if (gems.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Ukryte perełki',
          trailing: _SeeAllButton(landmarks: false),
        ),
        _HorizontalCards(
          children: [
            for (final listing in gems)
              _MiniCard(
                emoji: listing.bar.emoji,
                color: AppColors.amber,
                chip: formatDistance(listing.distanceMeters),
                title: listing.bar.name,
                subtitle: listing.bar.district,
                footer: listing.friendsRating == null
                    ? '★ ${formatRating(listing.bar.publicRating)} ogólnie'
                    : '★ ${formatRating(listing.friendsRating!)} znajomi',
                onTap: () => context.push('/bar/${listing.bar.id}'),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Teraz taniej": venues with a happy hour today, running ones first.
class _HappyHoursSection extends ConsumerWidget {
  const _HappyHoursSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = (ref.watch(barListingsProvider).valueOrNull ??
            const <BarListing>[])
        .where((l) => l.bar.happyHour != null)
        .toList()
      ..sort(
          (a, b) => (b.isHappyHour ? 1 : 0).compareTo(a.isHappyHour ? 1 : 0));
    if (listings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Teraz taniej'),
        _HorizontalCards(
          children: [
            for (final listing in listings)
              _MiniCard(
                emoji: listing.bar.emoji,
                color: AppColors.coral,
                chip: listing.isHappyHour ? 'teraz' : null,
                title: listing.bar.name,
                subtitle: listing.bar.happyHour!.label,
                footer: '🕒 ${listing.bar.happyHour!.hours}',
                onTap: () => context.push('/bar/${listing.bar.id}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _NewPlacesSection extends ConsumerWidget {
  const _NewPlacesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = (ref.watch(placesProvider).valueOrNull ?? const [])
        .where((place) => place.isNew)
        .toList();
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: '✨ Nowe w mieście'),
        _HorizontalCards(
          children: [
            for (final place in places)
              _MiniCard(
                emoji: place.emoji,
                color: AppColors.night,
                title: place.name,
                subtitle: place.district,
                footer: 'Nowe miejsce',
                onTap: () => context.push(
                  place.type == PlaceType.bar
                      ? '/bar/${place.id}'
                      : '/landmark/${place.id}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Districts without a passport stamp that have places to discover.
class _UnvisitedDistrictsCard extends ConsumerWidget {
  const _UnvisitedDistrictsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stamped = ref.watch(stampedDistrictsProvider);
    final places = ref.watch(placesProvider).valueOrNull ?? const [];
    final districts =
        ref.watch(districtsProvider).valueOrNull ?? const <CityDistrict>[];
    final withPlaces = places.map((p) => p.districtNo).toSet();
    final todo = districts
        .where((d) => withPlaces.contains(d.no) && !stamped.contains(d.no))
        .toList();
    if (todo.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/passport'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dzielnice do odkrycia',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pierwszy meldunek w nowej dzielnicy: +20 pkt i pieczątka '
                  'w Paszporcie.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final district in todo)
                      Chip(
                        avatar: const Icon(Icons.lock_open, size: 16),
                        label: Text('${district.roman} ${district.name}'),
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

class _PassportCard extends ConsumerWidget {
  const _PassportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stamped = ref.watch(stampedDistrictsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/passport'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🛂', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paszport Krakowa',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${stamped.length}/18 dzielnic · zbieraj pieczątki '
                        'za odkrywanie miasta',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stamped.length / 18,
                          minHeight: 6,
                          color: AppColors.green,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
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
        (a, b) => b.crowdAt(clock.minutes).compareTo(a.crowdAt(clock.minutes)),
      );
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
              for (final zone in sorted.take(3))
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
                  'Spokojniej: ${calmest.name} · +10 pkt za meldunek poza '
                  'tłokiem',
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
          SizedBox(
            width: 56,
            child: Text(
              level.label,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: level.textColor(Theme.of(context).brightness),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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

class _HorizontalCards extends StatelessWidget {
  const _HorizontalCards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            SizedBox(width: 168, child: children[index]),
      ),
    );
  }
}

/// Compact place card: coloured strip with the emoji (and an optional chip,
/// e.g. the distance), name, one-line subtitle and an accent footer.
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.onTap,
    this.chip,
  });

  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final String footer;
  final String? chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = this.chip;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              color: color.withAlpha(60),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 30)),
                  const Spacer(),
                  if (chip != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chip,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      footer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentText(theme.brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
