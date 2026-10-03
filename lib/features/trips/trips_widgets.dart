import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/place_repository.dart';

/// Horizontal list of curated trips (like saved lists in Google Maps).
class TripsCarousel extends ConsumerWidget {
  const TripsCarousel({super.key, this.preferred});

  /// Trips for this audience go first.
  final TripAudience? preferred;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = [...ref.watch(tripsProvider).valueOrNull ?? const <Trip>[]];
    final placesById = ref.watch(placesByIdProvider);
    if (trips.isEmpty) return const SizedBox.shrink();
    int rank(Trip trip) => trip.audience == preferred
        ? 0
        : trip.audience == TripAudience.both
            ? 1
            : 2;
    trips.sort((a, b) => rank(a).compareTo(rank(b)));

    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 260,
          child: TripCard(trip: trips[index], placesById: placesById),
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.placesById});

  final Trip trip;
  final Map<String, Place> placesById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stops = trip.stopIds.map((id) => placesById[id]).nonNulls.toList();
    final landmarks = stops.whereType<Landmark>().length;
    final bars = stops.length - landmarks;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/trip/${trip.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, Color(0xFF7CC68A)],
                ),
              ),
              child: Row(
                children: [
                  Text(trip.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stops.map((p) => p.emoji).join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🏛️ $landmarks '
                    '${pluralize(landmarks, 'atrakcja', 'atrakcje', 'atrakcji')}'
                    ' · 🍺 $bars '
                    '${pluralize(bars, 'bar', 'bary', 'barów')}'
                    ' · start ${formatClock(trip.startMinutes)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
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
