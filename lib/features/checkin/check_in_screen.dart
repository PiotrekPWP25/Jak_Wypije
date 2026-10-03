import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/check_in.dart';
import '../../data/models/landmark.dart';
import '../../data/models/place.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/city_repository.dart';
import '../../data/repositories/place_repository.dart';
import '../barobranie/planner_controller.dart';
import 'check_in_controller.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, this.preselectedPlaceId});

  /// When opened from a place's page, GPS/demo check-in targets this place.
  final String? preselectedPlaceId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  static const double _gpsRadiusMeters = 150;

  bool _busy = false;

  bool get _scannerSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final barId = capture.barcodes
        .map((barcode) => parseBarQr(barcode.rawValue))
        .nonNulls
        .firstOrNull;
    if (barId == null) return;
    await _checkIn(barId, CheckInMethod.qr);
  }

  Future<void> _checkIn(String placeId, CheckInMethod method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(barsProvider.future);
      await ref.read(landmarksProvider.future);
      if (!mounted) return;
      final placesById = ref.read(placesByIdProvider);
      final place = placesById[placeId];
      if (place == null) {
        _showSnack('Nie rozpoznano miejsca z tego kodu.');
        return;
      }
      final result = ref.read(checkInsProvider.notifier).checkIn(
            place,
            method: method,
            placesById: placesById,
            zone: ref.read(zonesByIdProvider)[place.zoneId],
            plan: ref.read(plannerProvider),
          );
      await showDialog<void>(
        context: context,
        builder: (_) => _CheckInResultDialog(place: place, result: result),
      );
      if (!mounted) return;
      if (result.success && context.canPop()) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkInByGps(List<Place> places) async {
    ref.invalidate(userPositionProvider);
    final position = await ref.read(userPositionProvider.future);
    if (!mounted) return;
    if (position == null) {
      _showSnack('Brak dostępu do lokalizacji. Włącz GPS i nadaj uprawnienia.');
      return;
    }
    final preselectedId = widget.preselectedPlaceId;
    final candidates = preselectedId == null
        ? places
        : places.where((place) => place.id == preselectedId);

    Place? nearest;
    var bestDistance = double.infinity;
    for (final place in candidates) {
      final distance = haversineMeters(position, place.location);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = place;
      }
    }
    if (nearest == null) {
      _showSnack('Nie znaleziono miejsca w pobliżu.');
      return;
    }
    if (bestDistance > _gpsRadiusMeters) {
      _showSnack(
        '${nearest.name} jest ${formatDistance(bestDistance)} stąd – '
        'podejdź bliżej (max ${_gpsRadiusMeters.round()} m).',
      );
      return;
    }
    await _checkIn(nearest.id, CheckInMethod.gps);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final places = ref.watch(placesProvider).valueOrNull ?? const <Place>[];
    final plan = ref.watch(plannerProvider);
    final preselected = places
        .where((place) => place.id == widget.preselectedPlaceId)
        .firstOrNull;
    // Demo list: the preselected place, else route stops first, then the rest.
    int order(Place place) {
      final index = plan.stopIds.indexOf(place.id);
      return index < 0 ? 999 : index;
    }

    final demoPlaces = preselected != null
        ? [preselected]
        : ([...places]..sort((a, b) => order(a).compareTo(order(b))));
    final isLandmark = preselected is Landmark;

    return Scaffold(
      appBar: AppBar(title: const Text('Zamelduj się')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _scannerSupported && !isLandmark
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(onDetect: _onDetect),
                          const _ScanFrame(),
                          if (_busy)
                            const ColoredBox(
                              color: Colors.black54,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      )
                    : const _ScannerUnavailable(),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(
                  preselected == null
                      ? 'Zeskanuj kod QR w barze albo melduj się przez GPS'
                      : 'Meldunek: ${preselected.name}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Punkty zdobywasz za odkrywanie: atrakcje, nowe dzielnice, '
                  'spacer i ukończone trasy. W barach punktujemy maks. '
                  '2 meldunki na wieczór.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _checkInByGps(places),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Melduję się przez GPS'),
                ),
                ExpansionTile(
                  title: const Text('Tryb demo (hackathon)'),
                  subtitle: const Text('Symuluj meldunek bez QR i GPS'),
                  children: [
                    for (final place in demoPlaces)
                      ListTile(
                        leading: Text(
                          place.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(place.name),
                        subtitle: Text(
                          '${place is Landmark ? 'Atrakcja' : 'Bar'} · '
                          '${place.district}'
                          '${plan.stopIds.contains(place.id) ? ' · w trasie' : ''}',
                        ),
                        onTap: _busy
                            ? null
                            : () => _checkIn(place.id, CheckInMethod.demo),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.amber, width: 3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ScannerUnavailable extends StatelessWidget {
  const _ScannerUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Atrakcje zaliczasz przez GPS (do 150 m), a skaner QR działa w barach. '
            'Użyj GPS albo trybu demo poniżej.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CheckInResultDialog extends StatelessWidget {
  const _CheckInResultDialog({required this.place, required this.result});

  final Place place;
  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title:
          Text(result.success ? '${place.emoji} Zameldowano!' : 'Hola, hola…'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.message),
          if (result.success) ...[
            const SizedBox(height: 12),
            Text(
              '+${result.points} pkt',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final bonus in result.bonuses) Text('• $bonus'),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
