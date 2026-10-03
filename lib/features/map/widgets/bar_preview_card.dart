import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../widgets/bar_info.dart';
import '../../../widgets/bar_status.dart';
import '../../barobranie/planner_controller.dart';
import '../../bars/bar_filters.dart';

class BarPreviewCard extends ConsumerWidget {
  const BarPreviewCard({
    super.key,
    required this.listing,
    required this.onClose,
  });

  final BarListing listing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bar = listing.bar;
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.stopIds.contains(bar.id)),
    );
    final status = barStatusOf(bar, inRoute: inPlan, crowd: listing.crowd);

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bar.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bar.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${bar.district} · '
                        '${formatDistance(listing.distanceMeters)} · '
                        '${bar.openHours}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Zamknij',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(status: status),
                FriendsScoreBadge(
                  rating: listing.friendsRating,
                  count: listing.friendsRatingCount,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            PriceChips(bar: bar),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(plannerProvider.notifier).toggle(bar.id),
                    icon: Icon(inPlan ? Icons.check : Icons.add),
                    label: Text(inPlan ? 'W trasie' : 'Do Barobrania'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/bar/${bar.id}'),
                    child: const Text('Szczegóły'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
