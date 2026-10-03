import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/bar_info.dart';
import '../../barobranie/planner_controller.dart';
import '../bar_filters.dart';

/// Booking-style result card.
class BarCard extends ConsumerWidget {
  const BarCard({super.key, required this.listing, required this.fromLabel});

  final BarListing listing;

  /// Name of the reference point distances are measured from.
  final String fromLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bar = listing.bar;
    final crowd = listing.crowd;
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.stopIds.contains(bar.id)),
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/bar/${bar.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(emoji: bar.emoji, isHiddenGem: bar.isHiddenGem),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bar.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bar.district} · ${formatDistance(listing.distanceMeters)} '
                          'od: $fromLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FriendsScoreBadge(
                          rating: listing.friendsRating,
                          count: listing.friendsRatingCount,
                        ),
                        const SizedBox(height: 4),
                        PublicRatingText(bar: bar),
                        if (bar.isNew ||
                            bar.nonAlcoholic ||
                            bar.happyHour != null) ...[
                          const SizedBox(height: 6),
                          BarBadges(bar: bar, happyNow: listing.isHappyHour),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PriceChips(bar: bar),
              const SizedBox(height: 10),
              Row(
                children: [
                  AmenityIcons(bar: bar),
                  if (crowd != null) CrowdBadge(level: crowd),
                  const SizedBox(width: 6),
                  Text(
                    listing.isOpen ? 'Otwarte' : 'Zamknięte',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: listing.isOpen ? AppColors.green : AppColors.coral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  inPlan
                      ? OutlinedButton.icon(
                          onPressed: () =>
                              ref.read(plannerProvider.notifier).remove(bar.id),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('W trasie'),
                        )
                      : FilledButton.icon(
                          onPressed: () =>
                              ref.read(plannerProvider.notifier).add(bar.id),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Do trasy'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.emoji, required this.isHiddenGem});

  final String emoji;
  final bool isHiddenGem;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE6A8), AppColors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 40)),
        ),
        if (isHiddenGem)
          Positioned(
            left: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brown,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💎 Perełka',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
