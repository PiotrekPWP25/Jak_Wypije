import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/platform/external_launcher.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/maps_link.dart';
import 'plan_calculator.dart';
import 'safe_return.dart';

/// Plain-text plan to paste into a chat with friends.
String planShareText(
  PlanSummary summary, {
  String title = 'Barobranie',
  SafeReturnOption? ride,
}) {
  final buffer = StringBuffer('$title – JakWypiję 🍺📍\n');
  for (var i = 0; i < summary.stops.length; i++) {
    final stop = summary.stops[i];
    buffer.writeln(
      '${i + 1}. ${formatClock(stop.arrivalMinutes)} ${stop.place.emoji} '
      '${stop.place.name} (${stop.place.district})',
    );
  }
  buffer.writeln(
    'Spacer: ${formatDistance(summary.totalWalkMeters)} · '
    'koniec ok. ${formatClock(summary.endMinutes)} · '
    'budżet ${summary.totalCost.label}',
  );
  final urls = googleMapsDirectionsUrls(
    [for (final stop in summary.stops) stop.place.location],
  );
  for (var i = 0; i < urls.length; i++) {
    final label = urls.length == 1 ? 'Trasa' : 'Trasa (część ${i + 1})';
    buffer.writeln('$label w Google Maps: ${urls[i]}');
  }
  final departure = ride?.departures.firstOrNull;
  if (ride != null && departure != null) {
    buffer.writeln(
      'Powrót: ${ride.stop.name}, linia ${departure.line.number} '
      'o ${formatClock(departure.minutes)}',
    );
  }
  return buffer.toString().trim();
}

/// "Open in Google Maps" + "Copy plan" buttons.
class RouteExportButtons extends StatelessWidget {
  const RouteExportButtons({
    super.key,
    required this.summary,
    this.title = 'Barobranie',
    this.ride,
  });

  final PlanSummary summary;
  final String title;
  final SafeReturnOption? ride;

  Future<void> _openInMaps(BuildContext context) async {
    final urls = googleMapsDirectionsUrls(
      [for (final stop in summary.stops) stop.place.location],
    );
    if (urls.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ExternalLauncher.openUrl(urls.first);
    if (opened) {
      if (urls.length > 1) {
        await Clipboard.setData(ClipboardData(text: urls.join('\n')));
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Długa trasa – otwarto 1. część, linki do kolejnych '
              'skopiowano do schowka.',
            ),
          ),
        );
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: urls.join('\n')));
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Nie udało się otworzyć Map – link skopiowano do schowka.',
        ),
      ),
    );
  }

  Future<void> _copyPlan(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: planShareText(summary, title: title, ride: ride)),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Plan skopiowany – wklej go znajomym na czacie.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRoute = summary.stops.length >= 2;
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: canRoute ? () => _openInMaps(context) : null,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Google Maps'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: summary.stops.isEmpty ? null : () => _copyPlan(context),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Kopiuj plan'),
          ),
        ),
      ],
    );
  }
}
