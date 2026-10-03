import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo.dart';
import '../../../data/models/bar.dart';
import '../../../data/models/fundraiser.dart';
import '../../../widgets/bar_status.dart';
import '../../../widgets/fundraiser_card.dart';
import '../../planner/planner_controller.dart';

class BarPreviewCard extends ConsumerWidget {
  const BarPreviewCard({
    super.key,
    required this.bar,
    required this.onClose,
    this.fundraiser,
    this.userPosition,
  });

  final Bar bar;
  final Fundraiser? fundraiser;
  final LatLng? userPosition;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = barStatusOf(bar, fundraiser);
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.barIds.contains(bar.id)),
    );
    final position = userPosition;
    final activeFundraiser = fundraiser;
    final subtitle = position == null
        ? bar.district
        : '${bar.district} · '
            '${formatDistance(haversineMeters(position, bar.location))}';

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
                      Text(
                        bar.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
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
                Text(
                  'Piwo od ${formatPln(bar.beerPrice)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (activeFundraiser != null && !activeFundraiser.isSaved) ...[
              const SizedBox(height: 12),
              FundraiserProgressBar(fundraiser: activeFundraiser),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(plannerProvider.notifier).toggle(bar.id),
                    icon: Icon(inPlan ? Icons.check : Icons.add),
                    label: Text(inPlan ? 'W planie' : 'Do planu'),
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
