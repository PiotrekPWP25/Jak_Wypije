import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/models/bar.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/evening_plan.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import '../../data/models/transit_stop.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../bars/bars_providers.dart';
import '../map/widgets/bar_marker.dart';
import '../trips/trips_widgets.dart';
import 'plan_calculator.dart';
import 'planner_controller.dart';
import 'route_export.dart';
import 'safe_return.dart';

String placeRoute(Place place) =>
    place is Landmark ? '/landmark/${place.id}' : '/bar/${place.id}';

/// "Barobranie": build a walking route of landmarks and bars on the map.
class BarobranieScreen extends ConsumerStatefulWidget {
  const BarobranieScreen({super.key});

  @override
  ConsumerState<BarobranieScreen> createState() => _BarobranieScreenState();
}

class _BarobranieScreenState extends ConsumerState<BarobranieScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Keeps the route above the bottom sheet (which covers about half).
  EdgeInsets _fitPadding() => EdgeInsets.fromLTRB(
        48,
        120,
        48,
        MediaQuery.sizeOf(context).height * 0.55,
      );

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(coordinates: points, padding: _fitPadding()),
    );
  }

  void _addPlaces({required bool landmarks}) {
    ref
        .read(distanceReferenceProvider.notifier)
        .set(DistanceReference.lastStop);
    ref.read(showLandmarksProvider.notifier).set(landmarks);
    context.go('/bars');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncValueView<List<Place>>(
        value: ref.watch(placesProvider),
        data: _buildBody,
      ),
    );
  }

  Widget _buildBody(List<Place> places) {
    final plan = ref.watch(plannerProvider);
    final zones = ref.watch(zonesByIdProvider);
    final transit =
        ref.watch(transitStopsProvider).valueOrNull ?? const <TransitStop>[];
    final placesById = {for (final place in places) place.id: place};
    final stops = resolveStops(plan, placesById);
    final summary = calculatePlan(plan, stops, zones: zones);
    final safeReturn = stops.isEmpty
        ? null
        : findSafeReturn(
            from: stops.last.location,
            leaveAt: summary.endMinutes,
            stops: transit,
          );
    final routePoints = [for (final place in stops) place.location];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                routePoints.isEmpty ? krakowCenter : routePoints.first,
            initialZoom: 14,
            initialCameraFit: routePoints.length > 1
                ? CameraFit.coordinates(
                    coordinates: routePoints,
                    padding: _fitPadding(),
                  )
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.hackyeah.jakwypije',
            ),
            PolylineLayer(
              polylines: [
                if (routePoints.length > 1)
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: AppColors.green,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                if (safeReturn != null)
                  Polyline(
                    points: [stops.last.location, safeReturn.stop.location],
                    strokeWidth: 4,
                    color: AppColors.night,
                    pattern: StrokePattern.dotted(),
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < stops.length; i++)
                  Marker(
                    point: stops[i].location,
                    width: 46,
                    height: 46,
                    child: stops[i] is Landmark
                        ? LandmarkMarker(
                            emoji: stops[i].emoji,
                            planIndex: i,
                            onTap: () => context.push(placeRoute(stops[i])),
                          )
                        : BarMarker(
                            emoji: stops[i].emoji,
                            color: AppColors.amber,
                            planIndex: i,
                            onTap: () => context.push(placeRoute(stops[i])),
                          ),
                  ),
                if (safeReturn != null)
                  Marker(
                    point: safeReturn.stop.location,
                    width: 36,
                    height: 36,
                    child: const TransitStopMarker(),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.route, color: AppColors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Barobranie',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (routePoints.isNotEmpty)
                  IconButton.filledTonal(
                    tooltip: 'Pokaż całą trasę',
                    onPressed: () => _fitRoute(routePoints),
                    icon: const Icon(Icons.fit_screen),
                  ),
              ],
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: stops.isEmpty ? 0.55 : 0.5,
          minChildSize: 0.16,
          maxChildSize: 0.92,
          builder: (context, scrollController) => _RouteSheet(
            controller: scrollController,
            bars: places.whereType<Bar>().toList(),
            plan: plan,
            summary: summary,
            zones: zones,
            safeReturn: safeReturn,
            onAddBars: () => _addPlaces(landmarks: false),
            onAddLandmarks: () => _addPlaces(landmarks: true),
          ),
        ),
      ],
    );
  }
}

class _RouteSheet extends ConsumerWidget {
  const _RouteSheet({
    required this.controller,
    required this.bars,
    required this.plan,
    required this.summary,
    required this.zones,
    required this.safeReturn,
    required this.onAddBars,
    required this.onAddLandmarks,
  });

  final ScrollController controller;
  final List<Bar> bars;
  final EveningPlan plan;
  final PlanSummary summary;
  final Map<String, CityZone> zones;
  final SafeReturnOption? safeReturn;
  final VoidCallback onAddBars;
  final VoidCallback onAddLandmarks;

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić trasę?'),
        content: const Text('Wszystkie przystanki zostaną usunięte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wyczyść'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(plannerProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(plannerProvider.notifier);
    final stops = summary.stops;
    final plannedIds = plan.stopIds.toSet();
    final option = safeReturn;
    final addButtons = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddLandmarks,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('+ Atrakcja'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddBars,
              icon: const Icon(Icons.local_bar_outlined),
              label: const Text('+ Bar'),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          stops.isEmpty
                              ? 'Twoja trasa'
                              : 'Twoja trasa · ${stops.length} '
                                  '${pluralize(stops.length, 'przystanek', 'przystanki', 'przystanków')}',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (stops.length > 2)
                        IconButton(
                          tooltip: 'Optymalizuj trasę',
                          icon: const Icon(Icons.auto_fix_high),
                          onPressed: () {
                            notifier.optimize([for (final s in stops) s.place]);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ułożono najkrótszą trasę od pierwszego '
                                  'przystanku.',
                                ),
                              ),
                            );
                          },
                        ),
                      if (stops.isNotEmpty)
                        IconButton(
                          tooltip: 'Wyczyść trasę',
                          icon: const Icon(Icons.delete_sweep_outlined),
                          onPressed: () => _confirmClear(context, ref),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (stops.isEmpty) ...[
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.route,
                title: 'Zbuduj swoje Barobranie',
                message: 'Połącz atrakcje miasta z barami – policzymy spacer, '
                    'budżet i bezpieczny powrót. Albo wybierz gotową trasę.',
              ),
            ),
            SliverToBoxAdapter(child: addButtons),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Gotowe trasy'),
            ),
            const SliverToBoxAdapter(child: TripsCarousel()),
          ] else ...[
            SliverToBoxAdapter(
              child: _SummaryCard(plan: plan, summary: summary),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: RouteExportButtons(summary: summary, ride: option),
              ),
            ),
            SliverReorderableList(
              itemCount: stops.length,
              onReorderItem: notifier.moveStop,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                elevation: 6,
                child: child,
              ),
              itemBuilder: (context, index) {
                final stop = stops[index];
                final crowded =
                    stop.warnings.any((w) => w.type == PlanWarningType.crowded);
                final alternative = crowded
                    ? calmerAlternative(
                        stop.place,
                        bars,
                        zones,
                        atMinutes: stop.arrivalMinutes,
                        excludeIds: plannedIds,
                      )
                    : null;
                return _StopTile(
                  key: ValueKey(stop.place.id),
                  index: index,
                  stop: stop,
                  drinksPerStop: plan.drinksPerStop,
                  alternative: alternative,
                  onRemove: () => notifier.remove(stop.place.id),
                  onReplace: alternative == null
                      ? null
                      : () => notifier.replace(stop.place.id, alternative.id),
                );
              },
            ),
            SliverToBoxAdapter(child: addButtons),
            if (option != null)
              SliverToBoxAdapter(
                child: SafeReturnCard(
                  option: option,
                  leaveAt: summary.endMinutes,
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.plan, required this.summary});

  final EveningPlan plan;
  final PlanSummary summary;

  Future<void> _pickStartTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: plan.startMinutes ~/ 60 % 24,
        minute: plan.startMinutes % 60,
      ),
      helpText: 'Godzina startu',
      cancelText: 'Anuluj',
      confirmText: 'Ustaw',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    ref
        .read(plannerProvider.notifier)
        .setStartMinutes(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(plannerProvider.notifier);
    final hasBars = summary.stops.any((s) => s.place is Bar);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Start',
                    value: formatClock(plan.startMinutes),
                    onTap: () => _pickStartTime(context, ref),
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Koniec',
                    value: formatClock(summary.endMinutes),
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Spacer',
                    value: formatDistance(summary.totalWalkMeters),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _SummaryStat(
                    label: 'Budżet',
                    value: summary.totalCost.label,
                  ),
                ),
              ],
            ),
            if (hasBars) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(child: Text('Napoje w barze (do budżetu)')),
                  IconButton(
                    onPressed: plan.drinksPerStop > 1
                        ? () =>
                            notifier.setDrinksPerStop(plan.drinksPerStop - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Mniej',
                  ),
                  Text(
                    '${plan.drinksPerStop}',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: plan.drinksPerStop <
                            PlannerNotifier.maxDrinksPerStop
                        ? () =>
                            notifier.setDrinksPerStop(plan.drinksPerStop + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Więcej',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 45, label: Text('45 min')),
                  ButtonSegment(value: 60, label: Text('1 h')),
                  ButtonSegment(value: 90, label: Text('1,5 h')),
                ],
                selected: {plan.minutesPerStop},
                onSelectionChanged: (selection) =>
                    notifier.setMinutesPerStop(selection.first),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${hasBars ? 'Czas w każdym barze · ' : ''}'
              '${formatDuration(summary.totalWalkMinutes)} spaceru · '
              '${summary.landmarkCount} '
              '${pluralize(summary.landmarkCount, 'atrakcja', 'atrakcje', 'atrakcji')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editable = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: editable ? AppColors.amber : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                if (editable) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.edit, size: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    super.key,
    required this.index,
    required this.stop,
    required this.drinksPerStop,
    required this.onRemove,
    this.alternative,
    this.onReplace,
  });

  final int index;
  final PlanStop stop;
  final int drinksPerStop;
  final VoidCallback onRemove;
  final Bar? alternative;
  final VoidCallback? onReplace;

  IconData _warningIcon(PlanWarningType type) => switch (type) {
        PlanWarningType.closed => Icons.do_not_disturb_on_outlined,
        PlanWarningType.closesEarly => Icons.schedule,
        PlanWarningType.crowded => Icons.groups,
        PlanWarningType.quietZone => Icons.bedtime_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = stop.place;
    final walkInfo = index == 0
        ? 'Start trasy'
        : '🚶 ${formatDuration(stop.walkMinutes)} · '
            '${formatDistance(stop.walkMeters)}';
    final details = place is Landmark
        ? '${place.category.label} · bilet: ${place.ticketLabel}'
        : '$drinksPerStop× piwo ${stop.cost.label}';
    final replacement = alternative;
    final replace = onReplace;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          ListTile(
            leading: ReorderableDragStartListener(
              index: index,
              child: CircleAvatar(
                backgroundColor:
                    place is Landmark ? AppColors.green : AppColors.amber,
                foregroundColor:
                    place is Landmark ? Colors.white : AppColors.brown,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            title: Text(
              '${place.emoji} ${place.name}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '$walkInfo\n'
              '${formatClock(stop.arrivalMinutes)}–'
              '${formatClock(stop.departureMinutes)} · $details',
            ),
            isThreeLine: true,
            trailing: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: 'Usuń z trasy',
            ),
            onTap: () => context.push(placeRoute(place)),
          ),
          for (final warning in stop.warnings)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _warningIcon(warning.type),
                    size: 18,
                    color: warning.type == PlanWarningType.quietZone
                        ? AppColors.night
                        : AppColors.coral,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning.message,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          if (replacement != null && replace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: replace,
                  icon: const Icon(Icons.swap_horiz, color: AppColors.green),
                  label: Text(
                    'Zamień na ${replacement.emoji} ${replacement.name} '
                    '(luźno)',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// End-of-route card: how to get home by night transport.
class SafeReturnCard extends StatelessWidget {
  const SafeReturnCard({
    super.key,
    required this.option,
    required this.leaveAt,
  });

  final SafeReturnOption option;
  final int leaveAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: AppColors.night.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round, color: AppColors.night),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bezpieczny powrót',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/safe-return'),
                  child: const Text('Szczegóły'),
                ),
              ],
            ),
            Text(
              'Po wyjściu o ${formatClock(leaveAt)}: '
              '${formatDuration(option.walkMinutes)} pieszo na przystanek '
              '${option.stop.name}.',
            ),
            const SizedBox(height: 8),
            for (final departure in option.departures)
              DepartureRow(departure: departure, from: leaveAt),
          ],
        ),
      ),
    );
  }
}

class DepartureRow extends StatelessWidget {
  const DepartureRow({super.key, required this.departure, required this.from});

  final Departure departure;
  final int from;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = departure.line;
    final wait = departure.minutes - from;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: line.isNight ? AppColors.night : AppColors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              line.number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${line.isNight ? '🌙 ' : ''}→ ${line.headsign}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatClock(departure.minutes),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'za ${formatDuration(wait)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
