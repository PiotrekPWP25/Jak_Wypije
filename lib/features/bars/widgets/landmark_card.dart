import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/landmark.dart';
import '../../barobranie/planner_controller.dart';
import '../bar_filters.dart';

/// Card for a city attraction in the "Atrakcje" list.
class LandmarkCard extends ConsumerWidget {
  const LandmarkCard({
    super.key,
    required this.listing,
    required this.fromLabel,
  });

  final LandmarkListing listing;
  final String fromLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final landmark = listing.landmark;
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.stopIds.contains(landmark.id)),
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/landmark/${landmark.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.green.withAlpha(35),
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: Text(
                  landmark.emoji,
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            landmark.name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (landmark.isNew)
                          const Text(
                            '✨ Nowe',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                    Text(
                      '${landmark.category.label} · ${landmark.district} · '
                      '${formatDistance(listing.distanceMeters)} od: $fromLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🎟️ ${landmark.ticketLabel} · '
                      '⏱️ ${formatDuration(landmark.visitMinutes)} · '
                      '🕒 ${landmark.openHours}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          landmark.isAlwaysOpen
                              ? 'Zawsze dostępne'
                              : listing.isOpen
                                  ? 'Otwarte'
                                  : 'Zamknięte',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: listing.isOpen
                                ? AppColors.green
                                : AppColors.coral,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        inPlan
                            ? OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(plannerProvider.notifier)
                                    .remove(landmark.id),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('W trasie'),
                              )
                            : FilledButton.icon(
                                onPressed: () => ref
                                    .read(plannerProvider.notifier)
                                    .add(landmark.id),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Do trasy'),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
