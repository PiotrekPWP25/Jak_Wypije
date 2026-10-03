import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/city_event.dart';
import '../../data/models/landmark.dart';
import '../../data/repositories/place_repository.dart';

/// Events in the next 7 days, soonest first.
final upcomingEventsProvider = Provider<List<UpcomingEvent>>((ref) {
  final events = ref.watch(eventsProvider).valueOrNull ?? const <CityEvent>[];
  return upcomingEvents(events, DateTime.now());
});

String _dayLabel(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Dziś';
  if (diff == 1) return 'Jutro';
  return DateFormat('EEEE', 'pl_PL').format(at);
}

class EventTile extends ConsumerWidget {
  const EventTile({super.key, required this.upcoming, this.showPlace = true});

  final UpcomingEvent upcoming;
  final bool showPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final event = upcoming.event;
    final place = ref.watch(placesByIdProvider)[event.placeId];
    final day = _dayLabel(upcoming.at, DateTime.now());
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Text(event.emoji, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(event.title),
      subtitle: Text(
        '$day ${formatClock(event.startMinutes)}'
        '${showPlace && place != null ? ' · ${place.name}' : ''}\n'
        '${event.description}',
      ),
      isThreeLine: true,
      onTap: place == null
          ? null
          : () => context.push(
                place is Landmark
                    ? '/landmark/${place.id}'
                    : '/bar/${place.id}',
              ),
    );
  }
}

/// "W tym tygodniu" card for the Start screen.
class UpcomingEventsCard extends ConsumerWidget {
  const UpcomingEventsCard({super.key, this.limit = 4});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingEventsProvider);
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final item in upcoming.take(limit)) EventTile(upcoming: item),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Wydarzenia przykładowe (demo) – docelowo z kalendarza miasta '
              'i od lokali partnerskich.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
