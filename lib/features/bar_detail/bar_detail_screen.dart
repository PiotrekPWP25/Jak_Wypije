import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bar.dart';
import '../../data/models/friend.dart';
import '../../data/models/price_range.dart';
import '../../data/models/review.dart';
import '../../data/models/transit_stop.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_info.dart';
import '../../widgets/bar_status.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/section_header.dart';
import '../barobranie/barobranie_screen.dart';
import '../barobranie/planner_controller.dart';
import '../barobranie/safe_return.dart';
import '../bars/bars_providers.dart';
import '../checkin/check_in_controller.dart';
import '../friends/reviews_controller.dart';
import '../profile/profile_providers.dart';
import 'add_review_dialog.dart';

class BarDetailScreen extends ConsumerWidget {
  const BarDetailScreen({super.key, required this.barId});

  final String barId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barAsync = ref.watch(barByIdProvider(barId));
    return Scaffold(
      appBar: AppBar(title: Text(barAsync.valueOrNull?.name ?? 'Bar')),
      body: AsyncValueView<Bar?>(
        value: barAsync,
        data: (bar) => bar == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Nie znaleziono baru',
              )
            : _BarDetailBody(bar: bar),
      ),
    );
  }
}

class _BarDetailBody extends ConsumerWidget {
  const _BarDetailBody({required this.bar});

  final Bar bar;

  Future<void> _addReview(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<ReviewDraft>(
      context: context,
      builder: (_) => AddReviewDialog(barName: bar.name),
    );
    if (draft == null) return;
    ref.read(myReviewsProvider.notifier).add(
          barId: bar.id,
          rating: draft.rating,
          comment: draft.comment,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dzięki za ocenę! +5 pkt')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listing = (ref.watch(barListingsProvider).valueOrNull ?? const [])
        .where((l) => l.bar.id == bar.id)
        .firstOrNull;
    final zone = ref.watch(zonesByIdProvider)[bar.zoneId];
    final clock = ref.watch(cityClockProvider);
    final transit =
        ref.watch(transitStopsProvider).valueOrNull ?? const <TransitStop>[];
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.barIds.contains(bar.id)),
    );
    final visits = ref
        .watch(checkInsProvider)
        .where((checkIn) => checkIn.barId == bar.id)
        .length;
    final reviews =
        (ref.watch(allReviewsProvider).valueOrNull ?? const <Review>[])
            .where((review) => review.barId == bar.id)
            .toList();
    final friends = ref.watch(friendsByIdProvider);
    final myName = ref.watch(userNameProvider);
    final status = barStatusOf(bar, inRoute: inPlan, crowd: listing?.crowd);
    final ride = findSafeReturn(
      from: bar.location,
      leaveAt: bar.closesAt,
      stops: transit,
    );
    final kitchen = bar.kitchenUntil;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE6A8), AppColors.amber],
                ),
              ),
              child: Text(bar.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bar.name, style: theme.textTheme.headlineSmall),
                  Text(
                    '${bar.district} · ${bar.address}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FriendsScoreBadge(
          rating: listing?.friendsRating,
          count: listing?.friendsRatingCount ?? 0,
        ),
        const SizedBox(height: 4),
        PublicRatingText(bar: bar),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(status: status),
            for (final tag in bar.tags)
              Chip(
                label: Text(tag),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(bar.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(plannerProvider.notifier).toggle(bar.id),
                icon: Icon(inPlan ? Icons.check : Icons.add),
                label: Text(inPlan ? 'W trasie' : 'Do Barobrania'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/checkin?bar=${bar.id}'),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Melduj się'),
              ),
            ),
          ],
        ),
        const SectionHeader(
          title: 'Ceny',
          padding: EdgeInsets.only(top: 24, bottom: 8),
        ),
        Card(
          child: Column(
            children: [
              _PriceRow(label: '🍺 Piwo 0,5 l', range: bar.beer),
              _PriceRow(label: '🥃 Shot', range: bar.shot),
              _PriceRow(label: '🍹 Drink', range: bar.drink),
              _PriceRow(
                label: '🍽️ Jedzenie (na osobę)',
                range: bar.food,
                emptyLabel: 'brak kuchni',
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Informacje',
          padding: EdgeInsets.only(top: 24, bottom: 8),
        ),
        _InfoRow(
          icon: Icons.schedule,
          label: 'Godziny otwarcia',
          value: '${bar.openHours}'
              '${listing == null ? '' : listing.isOpen ? ' · otwarte' : ' · zamknięte'}',
        ),
        _InfoRow(
          icon: Icons.restaurant,
          label: 'Kuchnia',
          value: kitchen == null ? 'brak' : 'do ${formatClock(kitchen)}',
        ),
        _InfoRow(
          icon: bar.acceptsCards ? Icons.credit_card : Icons.money,
          label: 'Płatność',
          value: bar.acceptsCards ? 'karta i gotówka' : 'tylko gotówka',
        ),
        if (visits > 0)
          _InfoRow(
            icon: Icons.verified_outlined,
            label: 'Twoje wizyty',
            value: '$visits',
          ),
        const SectionHeader(
          title: 'Dostępność',
          padding: EdgeInsets.only(top: 24, bottom: 8),
        ),
        _CheckRow(
          label: 'Wejście bez progów / podjazd',
          ok: bar.accessibility.stepFree,
        ),
        _CheckRow(
          label: 'Toaleta dla osób z niepełnosprawnościami',
          ok: bar.accessibility.accessibleToilet,
        ),
        _CheckRow(
          label: 'Cicha strefa (dla osób wrażliwych na bodźce)',
          ok: bar.accessibility.quietArea,
        ),
        if (zone != null) ...[
          SectionHeader(
            title: 'Okolica: ${zone.name}',
            padding: const EdgeInsets.only(top: 24, bottom: 8),
          ),
          Row(
            children: [
              CrowdBadge(level: zone.levelAt(clock.minutes)),
              const SizedBox(width: 8),
              Text(
                clock.isForecast
                    ? 'prognoza na ${formatClock(clock.minutes)}'
                    : 'teraz',
                style: theme.textTheme.bodySmall,
              ),
              if (zone.quietZone) ...[
                const SizedBox(width: 8),
                const Icon(Icons.bedtime, size: 16, color: AppColors.night),
                Text(' strefa ciszy', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(zone.note, style: theme.textTheme.bodySmall),
        ],
        if (ride != null) SafeReturnCard(option: ride, leaveAt: bar.closesAt),
        SectionHeader(
          title: 'Oceny znajomych',
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          trailing: TextButton.icon(
            onPressed: () => _addReview(context, ref),
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Oceń'),
          ),
        ),
        if (reviews.isEmpty)
          Text(
            'Nikt jeszcze nie ocenił tego baru – bądź pierwszy!',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          for (final review in reviews)
            _buildReviewTile(review, friends, myName),
      ],
    );
  }

  Widget _buildReviewTile(
    Review review,
    Map<String, Friend> friends,
    String myName,
  ) {
    final author = resolveAuthor(review, friends, myName);
    return ReviewTile(
      review: review,
      authorName: author.name,
      authorEmoji: author.emoji,
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.range,
    this.emptyLabel = 'brak',
  });

  final String label;
  final PriceRange? range;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final value = range;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value == null ? emptyLabel : value.label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel_outlined,
            size: 20,
            color: ok ? AppColors.green : AppColors.coral,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
