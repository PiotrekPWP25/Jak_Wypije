import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/bar.dart';
import '../../data/models/fundraiser.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_status.dart';
import '../barobranie/barobranie_providers.dart';
import '../planner/planner_controller.dart';
import 'widgets/bar_marker.dart';
import 'widgets/bar_preview_card.dart';

enum MapFilter { all, hiddenGems, barobranie }

extension _MapFilterLabel on MapFilter {
  String get label => switch (this) {
        MapFilter.all => 'Wszystkie',
        MapFilter.hiddenGems => 'Ukryte perełki',
        MapFilter.barobranie => 'Barobranie',
      };
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  MapFilter _filter = MapFilter.all;
  String? _selectedBarId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool _matchesFilter(Bar bar, Fundraiser? fundraiser) => switch (_filter) {
        MapFilter.all => true,
        MapFilter.hiddenGems => bar.isHiddenGem,
        MapFilter.barobranie => fundraiser != null,
      };

  Future<void> _centerOnUser() async {
    ref.invalidate(userPositionProvider);
    final position = await ref.read(userPositionProvider.future);
    if (!mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nie udało się ustalić lokalizacji – pokazuję centrum Krakowa.',
          ),
        ),
      );
      _mapController.move(krakowCenter, 14);
      return;
    }
    _mapController.move(position, 15);
  }

  @override
  Widget build(BuildContext context) {
    final barsAsync = ref.watch(barsProvider);
    return Scaffold(
      body: AsyncValueView<List<Bar>>(
        value: barsAsync,
        data: _buildMap,
      ),
      floatingActionButton: _selectedBarId == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  tooltip: 'Moja lokalizacja',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'checkin',
                  onPressed: () => context.push('/checkin'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Melduj się'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildMap(List<Bar> bars) {
    final fundraisers = ref.watch(fundraiserByBarIdProvider);
    final position = ref.watch(userPositionProvider).valueOrNull;
    final plan = ref.watch(plannerProvider);

    final barsById = {for (final bar in bars) bar.id: bar};
    final planIndexById = {
      for (var i = 0; i < plan.barIds.length; i++) plan.barIds[i]: i,
    };
    final planPoints =
        plan.barIds.map((id) => barsById[id]?.location).nonNulls.toList();
    final visible =
        bars.where((bar) => _matchesFilter(bar, fundraisers[bar.id])).toList();
    final selected = barsById[_selectedBarId];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: krakowCenter,
            initialZoom: 13.5,
            minZoom: 10,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _selectedBarId = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.hackyeah.jakwypije',
            ),
            if (planPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: planPoints,
                    strokeWidth: 4,
                    color: AppColors.amber.withAlpha(204),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final bar in visible)
                  Marker(
                    point: bar.location,
                    width: 46,
                    height: 46,
                    child: BarMarker(
                      emoji: bar.emoji,
                      color: barStatusOf(bar, fundraisers[bar.id]).color,
                      planIndex: planIndexById[bar.id],
                      selected: bar.id == _selectedBarId,
                      onTap: () => setState(() => _selectedBarId = bar.id),
                    ),
                  ),
                if (position != null)
                  Marker(
                    point: position,
                    width: 22,
                    height: 22,
                    child: const UserLocationDot(),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterBar(
                selected: _filter,
                onChanged: (filter) => setState(() {
                  _filter = filter;
                  _selectedBarId = null;
                }),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: _Legend(),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 8,
          bottom: 4,
          child: _OsmAttribution(),
        ),
        if (selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: BarPreviewCard(
              bar: selected,
              fundraiser: fundraisers[selected.id],
              userPosition: position,
              onClose: () => setState(() => _selectedBarId = null),
            ),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final MapFilter selected;
  final ValueChanged<MapFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (final filter in MapFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: filter == selected,
                onSelected: (_) => onChanged(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in BarStatus.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(status.label, style: textStyle),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
    );
  }
}
