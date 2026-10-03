import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/bar.dart';
import '../../data/models/evening_plan.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import 'plan_calculator.dart';
import 'planner_controller.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  void _optimize(BuildContext context, WidgetRef ref) {
    final bars = ref.read(barsProvider).valueOrNull;
    if (bars == null) return;
    ref
        .read(plannerProvider.notifier)
        .optimize(resolveStops(ref.read(plannerProvider), bars));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ułożono najkrótszą trasę od pierwszego baru.'),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić plan?'),
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
    final barsAsync = ref.watch(barsProvider);
    final plan = ref.watch(plannerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan wieczoru'),
        actions: [
          if (plan.barIds.length > 2)
            IconButton(
              tooltip: 'Optymalizuj trasę',
              icon: const Icon(Icons.auto_fix_high),
              onPressed: () => _optimize(context, ref),
            ),
          if (plan.barIds.isNotEmpty)
            IconButton(
              tooltip: 'Wyczyść plan',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: AsyncValueView<List<Bar>>(
        value: barsAsync,
        data: (bars) => _PlannerBody(bars: bars, plan: plan),
      ),
    );
  }
}

class _PlannerBody extends ConsumerWidget {
  const _PlannerBody({required this.bars, required this.plan});

  final List<Bar> bars;
  final EveningPlan plan;

  List<({Bar bar, double distance})> _suggestions(
    List<Bar> stops,
    LatLng origin,
  ) {
    final inPlan = {for (final bar in stops) bar.id};
    final from = stops.isEmpty ? origin : stops.last.location;
    final candidates = [
      for (final bar in bars)
        if (bar.isHiddenGem && !inPlan.contains(bar.id))
          (bar: bar, distance: haversineMeters(from, bar.location)),
    ]..sort((a, b) => a.distance.compareTo(b.distance));
    return candidates.take(4).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plannerProvider.notifier);
    final origin = ref.watch(userPositionProvider).valueOrNull ?? krakowCenter;
    final stops = resolveStops(plan, bars);
    final summary = calculatePlan(plan, stops);
    final suggestions = _suggestions(stops, origin);

    return CustomScrollView(
      slivers: [
        if (stops.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.route,
              title: 'Twój plan jest pusty',
              message: 'Dodaj bary z mapy albo wybierz propozycje poniżej. '
                  'Ułożymy trasę, policzymy spacer i budżet.',
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: _SummaryCard(plan: plan, summary: summary),
          ),
          SliverReorderableList(
            itemCount: summary.stops.length,
            onReorderItem: notifier.moveStop,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              elevation: 6,
              child: child,
            ),
            itemBuilder: (context, index) {
              final stop = summary.stops[index];
              return _StopTile(
                key: ValueKey(stop.bar.id),
                index: index,
                stop: stop,
                drinksPerStop: plan.drinksPerStop,
                onRemove: () => notifier.remove(stop.bar.id),
              );
            },
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: stops.isEmpty
                  ? 'Ukryte perełki w pobliżu'
                  : 'Ukryte perełki blisko ostatniego przystanku',
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              for (final suggestion in suggestions)
                _SuggestionTile(
                  bar: suggestion.bar,
                  distance: suggestion.distance,
                  onAdd: () => notifier.add(suggestion.bar.id),
                ),
            ]),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    final stopCount = summary.stops.length;
    final drinks = plan.drinksPerStop * stopCount;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  child: _SummaryStat(
                    label: 'Budżet',
                    value: formatPln(summary.totalCost, whole: true),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(child: Text('Napoje w każdym barze')),
                IconButton(
                  onPressed: plan.drinksPerStop > 1
                      ? () => notifier.setDrinksPerStop(plan.drinksPerStop - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Mniej',
                ),
                Text('${plan.drinksPerStop}', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: plan.drinksPerStop < PlannerNotifier.maxDrinksPerStop
                      ? () => notifier.setDrinksPerStop(plan.drinksPerStop + 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Więcej',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Czas w każdym barze'),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Text(
              '$stopCount ${pluralize(stopCount, 'przystanek', 'przystanki', 'przystanków')}'
              ' · ${formatDuration(summary.totalWalkMinutes)} spaceru'
              ' · $drinks ${pluralize(drinks, 'napój', 'napoje', 'napojów')}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pokaż trasę na mapie'),
              ),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
  });

  final int index;
  final PlanStop stop;
  final int drinksPerStop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final walkInfo = index == 0
        ? 'Start trasy'
        : '🚶 ${formatDuration(stop.walkMinutes)} · '
            '${formatDistance(stop.walkMeters)}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: CircleAvatar(
            backgroundColor: AppColors.amber,
            foregroundColor: Colors.black,
            child: Text('${index + 1}'),
          ),
        ),
        title: Text('${stop.bar.emoji} ${stop.bar.name}'),
        subtitle: Text(
          '$walkInfo\n'
          '${formatClock(stop.arrivalMinutes)}–'
          '${formatClock(stop.departureMinutes)} · '
          '$drinksPerStop× ≈ ${formatPln(stop.cost, whole: true)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close),
          tooltip: 'Usuń z planu',
        ),
        onTap: () => context.push('/bar/${stop.bar.id}'),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.bar,
    required this.distance,
    required this.onAdd,
  });

  final Bar bar;
  final double distance;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(bar.emoji, style: const TextStyle(fontSize: 28)),
      title: Text(bar.name),
      subtitle: Text(
        '${bar.district} · ${formatDistance(distance)} · '
        'piwo ${formatPln(bar.beerPrice)}',
      ),
      trailing: IconButton.filledTonal(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        tooltip: 'Dodaj do planu',
      ),
      onTap: () => context.push('/bar/${bar.id}'),
    );
  }
}
