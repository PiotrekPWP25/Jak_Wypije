import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/time.dart';
import '../../data/location/location_provider.dart';
import '../../data/repositories/place_repository.dart';
import '../../data/models/transit_stop.dart';

import '../../data/repositories/city_repository.dart';
import '../../widgets/empty_state.dart';
import '../map/widgets/bar_marker.dart';
import 'barobranie_screen.dart';
import 'plan_calculator.dart';
import 'planner_controller.dart';
import 'safe_return.dart';

/// Smart City: plan the ride home with night public transport.
class SafeReturnScreen extends ConsumerWidget {
  const SafeReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final placesById = ref.watch(placesByIdProvider);
    final plan = ref.watch(plannerProvider);
    final zones = ref.watch(zonesByIdProvider);
    final transit =
        ref.watch(transitStopsProvider).valueOrNull ?? const <TransitStop>[];
    final position = ref.watch(userPositionProvider).valueOrNull;

    final stops = resolveStops(plan, placesById);
    final LatLng from;
    final int leaveAt;
    final String fromLabel;
    if (stops.isNotEmpty) {
      from = stops.last.location;
      leaveAt = calculatePlan(plan, stops, zones: zones).endMinutes;
      fromLabel = 'z: ${stops.last.name} (koniec trasy)';
    } else {
      from = position ?? krakowCenter;
      leaveAt = eveningMinutes(DateTime.now());
      fromLabel = position == null ? 'z: Rynek Główny' : 'z Twojej lokalizacji';
    }
    final option = findSafeReturn(from: from, leaveAt: leaveAt, stops: transit);

    return Scaffold(
      appBar: AppBar(title: const Text('Bezpieczny powrót')),
      body: option == null
          ? const EmptyState(
              icon: Icons.directions_bus,
              title: 'Brak kursów w pobliżu',
              message: 'Nie znaleźliśmy odjazdów – rozważ taksówkę.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.coordinates(
                        coordinates: [from, option.stop.location],
                        padding: const EdgeInsets.all(56),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'pl.hackyeah.jakwypije',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [from, option.stop.location],
                            strokeWidth: 4,
                            color: AppColors.night,
                            pattern: StrokePattern.dotted(),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: from,
                            width: 22,
                            height: 22,
                            child: const UserLocationDot(),
                          ),
                          Marker(
                            point: option.stop.location,
                            width: 36,
                            height: 36,
                            child: const TransitStopMarker(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.stop.name,
                          style: theme.textTheme.headlineSmall),
                      Text(
                        '$fromLabel · ${formatDistance(option.walkMeters)}, '
                        '${formatDuration(option.walkMinutes)} pieszo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Najbliższe odjazdy po ${formatClock(leaveAt)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final departure in option.departures)
                        DepartureRow(departure: departure, from: leaveAt),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(safeReturnsProvider.notifier)
                                .record();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Miłego powrotu! Napisz znajomym, gdy '
                                  'dotrzesz do domu. 🚋',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Wracam tym kursem'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _Tip(
                        icon: Icons.light_mode_outlined,
                        text: 'Idź oświetlonymi, głównymi ulicami – trasa '
                            'na mapie to linia prosta, nie nawigacja.',
                      ),
                      const _Tip(
                        icon: Icons.confirmation_number_outlined,
                        text: 'Bilet kup przed wejściem: biletomat lub '
                            'aplikacja przewoźnika.',
                      ),
                      const _Tip(
                        icon: Icons.info_outline,
                        text: 'Rozkład przykładowy (demo). Wersja produkcyjna '
                            'korzysta z otwartych danych GTFS ZTP Kraków.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.night),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
