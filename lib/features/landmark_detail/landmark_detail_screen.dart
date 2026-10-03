import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/landmark.dart';
import '../../data/models/transit_stop.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_info.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../barobranie/barobranie_screen.dart';
import '../barobranie/planner_controller.dart';
import '../barobranie/safe_return.dart';
import '../checkin/check_in_controller.dart';
import '../events/events_widgets.dart';

class LandmarkDetailScreen extends ConsumerWidget {
  const LandmarkDetailScreen({super.key, required this.landmarkId});

  final String landmarkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(landmarkByIdProvider(landmarkId));
    return Scaffold(
      appBar: AppBar(title: Text(async.valueOrNull?.name ?? 'Atrakcja')),
      body: AsyncValueView<Landmark?>(
        value: async,
        data: (landmark) => landmark == null
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'Nie znaleziono atrakcji',
              )
            : _Body(landmark: landmark),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.landmark});

  final Landmark landmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clock = ref.watch(cityClockProvider);
    final zone = ref.watch(zonesByIdProvider)[landmark.zoneId];
    final inPlan = ref.watch(
      plannerProvider.select((plan) => plan.stopIds.contains(landmark.id)),
    );
    final visited =
        ref.watch(checkInsProvider).any((c) => c.placeId == landmark.id);
    final events = ref
        .watch(upcomingEventsProvider)
        .where((e) => e.event.placeId == landmark.id)
        .toList();
    final transit =
        ref.watch(transitStopsProvider).valueOrNull ?? const <TransitStop>[];
    final ride = findSafeReturn(
      from: landmark.location,
      leaveAt: clock.minutes,
      stops: transit,
    );
    final open = landmark.isOpenAt(clock.minutes);

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
                color: AppColors.green.withAlpha(40),
                border: Border.all(color: AppColors.green, width: 2),
              ),
              child: Text(landmark.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(landmark.name, style: theme.textTheme.headlineSmall),
                  Text(
                    '${landmark.category.label} · ${landmark.district}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (landmark.isNew || visited) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (landmark.isNew) const Chip(label: Text('✨ Nowe')),
              if (visited) const Chip(label: Text('✅ Odwiedzone')),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(landmark.description, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    ref.read(plannerProvider.notifier).toggle(landmark.id),
                icon: Icon(inPlan ? Icons.check : Icons.add),
                label: Text(inPlan ? 'W trasie' : 'Do trasy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/checkin?place=${landmark.id}'),
                icon: const Icon(Icons.my_location),
                label: const Text('Melduj się'),
              ),
            ),
          ],
        ),
        const SectionHeader(
          title: 'Informacje',
          padding: EdgeInsets.only(top: 24, bottom: 8),
        ),
        _Info(
          icon: Icons.schedule,
          label: 'Godziny',
          value: '${landmark.openHours}'
              '${landmark.isAlwaysOpen ? '' : open ? ' · otwarte' : ' · zamknięte'}',
        ),
        _Info(
          icon: Icons.confirmation_number_outlined,
          label: 'Bilet',
          value: landmark.ticketLabel,
        ),
        _Info(
          icon: Icons.timer_outlined,
          label: 'Czas zwiedzania',
          value: formatDuration(landmark.visitMinutes),
        ),
        _Info(
          icon: Icons.emoji_events_outlined,
          label: 'Za meldunek',
          value: '+15 pkt (pierwszy raz +5)',
        ),
        if (zone != null) ...[
          SectionHeader(
            title: 'Okolica: ${zone.name}',
            padding: const EdgeInsets.only(top: 24, bottom: 8),
          ),
          Row(
            children: [
              CrowdBadge(level: zone.levelAt(clock.minutes)),
              if (zone.quietZone) ...[
                const SizedBox(width: 8),
                const Icon(Icons.bedtime, size: 16, color: AppColors.night),
                Text(' strefa ciszy', style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ],
        if (events.isNotEmpty) ...[
          const SectionHeader(
            title: 'Wydarzenia tutaj',
            padding: EdgeInsets.only(top: 24, bottom: 8),
          ),
          for (final event in events)
            EventTile(upcoming: event, showPlace: false),
        ],
        if (ride != null) SafeReturnCard(option: ride, leaveAt: clock.minutes),
        const SizedBox(height: 12),
        Text(
          'Godziny i ceny biletów są przybliżone – sprawdź przed wyjściem.',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});

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
          Icon(icon, size: 20, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
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
