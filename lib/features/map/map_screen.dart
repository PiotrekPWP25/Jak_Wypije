import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/city_zone.dart';
import '../../data/models/transit_stop.dart';
import '../../data/repositories/city_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_info.dart';
import '../../widgets/bar_status.dart';
import '../barobranie/planner_controller.dart';
import '../bars/bar_filters.dart';
import '../bars/bars_providers.dart';
import 'widgets/bar_marker.dart';
import 'widgets/bar_preview_card.dart';

/// Map overlays and filters toggled with chips.
enum MapLayer { hiddenGems, barrierFree, crowds, quietZones, nightTransit }

extension _MapLayerLabel on MapLayer {
  String get label => switch (this) {
        MapLayer.hiddenGems => '💎 Perełki',
        MapLayer.barrierFree => '♿ Bez barier',
        MapLayer.crowds => '👥 Tłok teraz',
        MapLayer.quietZones => '🌙 Strefy ciszy',
        MapLayer.nightTransit => '🚋 Nocne MPK',
      };
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final Set<MapLayer> _layers = {MapLayer.crowds};
  String? _selectedBarId;
  TransitStop? _selectedStop;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _toggle(MapLayer layer) => setState(() {
        if (!_layers.remove(layer)) _layers.add(layer);
        _selectedBarId = null;
      });

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
    final listings = ref.watch(barListingsProvider);
    return Scaffold(
      body: AsyncValueView<List<BarListing>>(
        value: listings,
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

  Widget _buildMap(List<BarListing> listings) {
    final position = ref.watch(userPositionProvider).valueOrNull;
    final plan = ref.watch(plannerProvider);
    final zones = ref.watch(zonesProvider).valueOrNull ?? const <CityZone>[];
    final stops =
        ref.watch(transitStopsProvider).valueOrNull ?? const <TransitStop>[];
    final clock = ref.watch(cityClockProvider);

    final byId = {for (final listing in listings) listing.bar.id: listing};
    final planIndexById = {
      for (var i = 0; i < plan.barIds.length; i++) plan.barIds[i]: i,
    };
    final planPoints =
        plan.barIds.map((id) => byId[id]?.bar.location).nonNulls.toList();
    final visible = listings.where((listing) {
      if (_layers.contains(MapLayer.hiddenGems) && !listing.bar.isHiddenGem) {
        return false;
      }
      if (_layers.contains(MapLayer.barrierFree) &&
          !listing.bar.accessibility.isBarrierFree) {
        return false;
      }
      return true;
    }).toList();
    final selected = byId[_selectedBarId];
    final stop = _selectedStop;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: krakowCenter,
            initialZoom: 13.5,
            minZoom: 10,
            maxZoom: 18,
            onTap: (_, __) => setState(() {
              _selectedBarId = null;
              _selectedStop = null;
            }),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.hackyeah.jakwypije',
            ),
            if (_layers.contains(MapLayer.crowds) ||
                _layers.contains(MapLayer.quietZones))
              CircleLayer(
                circles: [
                  for (final zone in zones)
                    if (_layers.contains(MapLayer.crowds))
                      CircleMarker(
                        point: zone.center,
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color: zone.levelAt(clock.minutes).color.withAlpha(55),
                        borderColor: zone.levelAt(clock.minutes).color,
                        borderStrokeWidth: 1.5,
                      ),
                  for (final zone in zones)
                    if (_layers.contains(MapLayer.quietZones) && zone.quietZone)
                      CircleMarker(
                        point: zone.center,
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color: _layers.contains(MapLayer.crowds)
                            ? Colors.transparent
                            : AppColors.night.withAlpha(45),
                        borderColor: AppColors.night,
                        borderStrokeWidth: 3,
                      ),
                ],
              ),
            if (planPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: planPoints,
                    strokeWidth: 4,
                    color: AppColors.green,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_layers.contains(MapLayer.nightTransit))
                  for (final transit in stops)
                    if (transit.hasNightLines)
                      Marker(
                        point: transit.location,
                        width: 30,
                        height: 30,
                        child: TransitStopMarker(
                          onTap: () => setState(() {
                            _selectedStop = transit;
                            _selectedBarId = null;
                          }),
                        ),
                      ),
                for (final listing in visible)
                  Marker(
                    point: listing.bar.location,
                    width: 46,
                    height: 46,
                    child: BarMarker(
                      emoji: listing.bar.emoji,
                      color: barStatusOf(
                        listing.bar,
                        inRoute: planIndexById.containsKey(listing.bar.id),
                        crowd: listing.crowd,
                      ).color,
                      planIndex: planIndexById[listing.bar.id],
                      selected: listing.bar.id == _selectedBarId,
                      onTap: () => setState(() {
                        _selectedBarId = listing.bar.id;
                        _selectedStop = null;
                      }),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    for (final layer in MapLayer.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(layer.label),
                          selected: _layers.contains(layer),
                          onSelected: (_) => _toggle(layer),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _Legend(
                  showCrowds: _layers.contains(MapLayer.crowds),
                  isForecast: clock.isForecast,
                  minutes: clock.minutes,
                ),
              ),
            ],
          ),
        ),
        const Positioned(left: 8, bottom: 4, child: _OsmAttribution()),
        if (selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: BarPreviewCard(
              listing: selected,
              onClose: () => setState(() => _selectedBarId = null),
            ),
          )
        else if (stop != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 96,
            child: _StopCard(
              stop: stop,
              minutes: clock.minutes,
              onClose: () => setState(() => _selectedStop = null),
            ),
          ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.minutes,
    required this.onClose,
  });

  final TransitStop stop;
  final int minutes;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bus, color: AppColors.night),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(stop.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Zamknij',
                ),
              ],
            ),
            for (final line in stop.lines)
              Text(
                '${line.isNight ? '🌙' : '🚋'} ${line.number} → ${line.headsign}'
                ' · ${line.departuresFrom(minutes, limit: 2).map(formatClock).join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.showCrowds,
    required this.isForecast,
    required this.minutes,
  });

  final bool showCrowds;
  final bool isForecast;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    Widget dot(Color color, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: textStyle),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in BarStatus.values)
              dot(status.color, status.label),
            if (showCrowds)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isForecast
                      ? 'Tłok: prognoza ${formatClock(minutes)}'
                      : 'Tłok: teraz ${formatClock(minutes)}',
                  style: textStyle?.copyWith(fontWeight: FontWeight.w700),
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
