import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/bar.dart';
import '../../data/models/friend.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_status.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fundraiser_card.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/section_header.dart';
import '../barobranie/barobranie_providers.dart';
import '../checkin/check_in_controller.dart';
import '../friends/reviews_controller.dart';
import '../planner/planner_controller.dart';
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
    final fundraiser = ref.watch(fundraiserByBarIdProvider)[bar.id];
    final status = barStatusOf(bar, fundraiser);
    final position = ref.watch(userPositionProvider).valueOrNull;
    final distance =
        position == null ? null : haversineMeters(position, bar.location);
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.barIds.contains(bar.id)),
    );
    final visits = ref
        .watch(checkInsProvider)
        .where((checkIn) => checkIn.barId == bar.id)
        .length;
    final reviews = (ref.watch(allReviewsProvider).valueOrNull ??
            const <Review>[])
        .where((review) => review.barId == bar.id)
        .toList();
    final friends = ref.watch(friendsByIdProvider);
    final myName = ref.watch(userNameProvider);
    final average = reviews.isEmpty
        ? null
        : reviews.map((review) => review.rating).reduce((a, b) => a + b) /
            reviews.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(bar.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bar.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.schedule,
          label: 'Godziny otwarcia',
          value: bar.openHours,
        ),
        _InfoRow(
          icon: Icons.sports_bar,
          label: 'Piwo od',
          value: formatPln(bar.beerPrice),
        ),
        _InfoRow(
          icon: Icons.payments_outlined,
          label: 'Poziom cen',
          value: 'zł' * bar.priceLevel,
        ),
        if (distance != null)
          _InfoRow(
            icon: Icons.directions_walk,
            label: 'Odległość',
            value: '${formatDistance(distance)} · '
                '${formatDuration(walkingMinutes(distance))} pieszo',
          ),
        _InfoRow(
          icon: Icons.star_outline,
          label: 'Ocena znajomych',
          value: average == null
              ? 'Brak ocen'
              : '${average.toStringAsFixed(1).replaceAll('.', ',')} / 5 '
                  '(${reviews.length})',
        ),
        if (visits > 0)
          _InfoRow(
            icon: Icons.verified_outlined,
            label: 'Twoje wizyty',
            value: '$visits',
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
                label: Text(inPlan ? 'W planie' : 'Dodaj do planu'),
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
        if (fundraiser != null) ...[
          const SizedBox(height: 16),
          FundraiserCard(
            fundraiser: fundraiser,
            bar: bar,
            margin: EdgeInsets.zero,
            onTap: () => context.push('/fundraiser/${fundraiser.id}'),
          ),
        ],
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
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
