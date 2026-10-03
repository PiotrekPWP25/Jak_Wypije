import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/geo.dart';
import '../../data/location/location_provider.dart';
import '../../data/models/bar.dart';
import '../../data/models/check_in.dart';
import '../../data/repositories/bar_repository.dart';
import '../barobranie/barobranie_providers.dart';
import 'check_in_controller.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, this.preselectedBarId});

  /// When opened from a bar's page, GPS/demo check-in targets this bar.
  final String? preselectedBarId;

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

  Future<void> _checkIn(String barId, CheckInMethod method) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bars = await ref.read(barsProvider.future);
      if (!mounted) return;
      final bar = bars.where((b) => b.id == barId).firstOrNull;
      if (bar == null) {
        _showSnack('Nie rozpoznano baru z tego kodu.');
        return;
      }
      final fundraiser = ref.read(fundraiserByBarIdProvider)[bar.id];
      final result = ref
          .read(checkInsProvider.notifier)
          .checkIn(bar, method: method, fundraiser: fundraiser);
      await showDialog<void>(
        context: context,
        builder: (_) => _CheckInResultDialog(bar: bar, result: result),
      );
      if (!mounted) return;
      if (result.success && context.canPop()) context.pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkInByGps(List<Bar> bars) async {
    ref.invalidate(userPositionProvider);
    final position = await ref.read(userPositionProvider.future);
    if (!mounted) return;
    if (position == null) {
      _showSnack('Brak dostępu do lokalizacji. Włącz GPS i nadaj uprawnienia.');
      return;
    }
    final preselectedId = widget.preselectedBarId;
    final candidates = preselectedId == null
        ? bars
        : bars.where((bar) => bar.id == preselectedId);

    Bar? nearest;
    var bestDistance = double.infinity;
    for (final bar in candidates) {
      final distance = haversineMeters(position, bar.location);
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = bar;
      }
    }
    if (nearest == null) {
      _showSnack('Nie znaleziono baru w pobliżu.');
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
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    final preselected =
        bars.where((bar) => bar.id == widget.preselectedBarId).firstOrNull;
    final demoBars = preselected == null ? bars : [preselected];

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
                child: _scannerSupported
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
                      ? 'Zeskanuj kod QR przy barze'
                      : 'Zeskanuj kod QR w: ${preselected.name}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Każdy bar partnerski ma naklejkę z kodem JakWypiję. '
                  'Za ukryte perełki i ratowane bary dostajesz bonusy!',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _checkInByGps(bars),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Nie mam kodu – melduję się przez GPS'),
                ),
                ExpansionTile(
                  title: const Text('Tryb demo (hackathon)'),
                  subtitle: const Text('Symuluj zeskanowanie kodu'),
                  children: [
                    for (final bar in demoBars)
                      ListTile(
                        leading: Text(
                          bar.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(bar.name),
                        subtitle: Text(bar.qrPayload),
                        onTap: _busy
                            ? null
                            : () => _checkIn(bar.id, CheckInMethod.demo),
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
            'Skaner QR działa na Androidzie, iOS, macOS i w przeglądarce. '
            'Użyj GPS albo trybu demo poniżej.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CheckInResultDialog extends StatelessWidget {
  const _CheckInResultDialog({required this.bar, required this.result});

  final Bar bar;
  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(result.success ? '${bar.emoji} Zameldowano!' : 'Hola, hola…'),
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
