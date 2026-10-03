import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/landmark.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state.dart';
import '../barobranie/plan_calculator.dart';
import '../barobranie/planner_controller.dart';
import '../barobranie/route_export.dart';
import '../map/widgets/bar_marker.dart';

/// Preview of a curated trip before loading it into Barobranie.
class TripPreviewScreen extends ConsumerWidget {
  const TripPreviewScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _useTrip(BuildContext context, WidgetRef ref, Trip trip) async {
    final current = ref.read(plannerProvider);
    if (current.stopIds.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Zastąpić obecną trasę?'),
          content: Text(
            'Masz już ${current.stopIds.length} przystanki w Barobraniu. '
            'Trasa „${trip.title}” je zastąpi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Zastąp'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    ref.read(plannerProvider.notifier).loadTrip(trip);
    if (context.mounted) context.go('/barobranie');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gotowa trasa')),
      body: AsyncValueView<List<Trip>>(
        value: tripsAsync,
        data: (trips) {
          final trip = trips.where((t) => t.id == tripId).firstOrNull;
          if (trip == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Nie znaleziono trasy',
            );
          }
          return _buildBody(context, ref, trip);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Trip trip) {
    final theme = Theme.of(context);
    final placesById = ref.watch(placesByIdProvider);
    final zones = ref.watch(zonesByIdProvider);
    final plan = ref.watch(plannerProvider).copyWith(
          stopIds: trip.stopIds,
          startMinutes: trip.startMinutes,
        );
    final places = resolveStops(plan, placesById);
    final summary = calculatePlan(plan, places, zones: zones);
    final points = [for (final place in places) place.location];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (points.length > 1)
          SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(40),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'pl.hackyeah.jakwypije',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 5,
                      color: AppColors.green,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < places.length; i++)
                      Marker(
                        point: places[i].location,
                        width: 40,
                        height: 40,
                        child: places[i] is Landmark
                            ? LandmarkMarker(
                                emoji: places[i].emoji,
                                planIndex: i,
                                onTap: () {},
                              )
                            : BarMarker(
                                emoji: places[i].emoji,
                                color: AppColors.amber,
                                planIndex: i,
                                onTap: () {},
                              ),
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
              Text(
                '${trip.emoji} ${trip.title}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(trip.subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill('🕒 ${formatClock(trip.startMinutes)}–'
                      '${formatClock(summary.endMinutes)}'),
                  _Pill('🚶 ${formatDistance(summary.totalWalkMeters)}'),
                  _Pill('🏛️ ${summary.landmarkCount} atrakcje'),
                  _Pill('💰 ${summary.totalCost.label}'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _useTrip(context, ref, trip),
                  icon: const Icon(Icons.route),
                  label: const Text('Wybierz tę trasę'),
                ),
              ),
              const SizedBox(height: 8),
              RouteExportButtons(summary: summary, title: trip.title),
            ],
          ),
        ),
        for (var i = 0; i < summary.stops.length; i++)
          _TripStopTile(index: i, stop: summary.stops[i]),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TripStopTile extends StatelessWidget {
  const _TripStopTile({required this.index, required this.stop});

  final int index;
  final PlanStop stop;

  @override
  Widget build(BuildContext context) {
    final place = stop.place;
    final isLandmark = place is Landmark;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isLandmark ? AppColors.green : AppColors.amber,
        foregroundColor: isLandmark ? Colors.white : AppColors.brown,
        child: Text('${index + 1}'),
      ),
      title: Text('${place.emoji} ${place.name}'),
      subtitle: Text(
        '${formatClock(stop.arrivalMinutes)}–'
        '${formatClock(stop.departureMinutes)} · ${place.district}'
        '${stop.warnings.isEmpty ? '' : ' · ⚠️ ${stop.warnings.first.message}'}',
      ),
      onTap: () => context.push(
        isLandmark ? '/landmark/${place.id}' : '/bar/${place.id}',
      ),
    );
  }
}
