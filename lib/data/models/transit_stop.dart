import 'package:latlong2/latlong.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/time.dart';

/// A public transport line serving a stop, with a regular headway.
///
/// Times are on the evening axis, so night lines run e.g. 23:30 → 28:30.
class TransitLine {
  const TransitLine({
    required this.number,
    required this.headsign,
    required this.isNight,
    required this.firstDeparture,
    required this.lastDeparture,
    required this.everyMinutes,
  });

  factory TransitLine.fromJson(Map<String, dynamic> json) {
    return TransitLine(
      number: json['number'] as String,
      headsign: json['headsign'] as String,
      isNight: json['night'] as bool? ?? false,
      firstDeparture: parseEveningTime(json['from'] as String),
      lastDeparture: parseEveningTime(json['to'] as String),
      everyMinutes: (json['every'] as num).toInt(),
    );
  }

  final String number;
  final String headsign;
  final bool isNight;
  final int firstDeparture;
  final int lastDeparture;
  final int everyMinutes;

  /// Departures at or after [from] (evening axis), at most [limit].
  List<int> departuresFrom(int from, {int limit = 3}) {
    final result = <int>[];
    for (var time = firstDeparture;
        time <= lastDeparture && result.length < limit;
        time += everyMinutes) {
      if (time >= from) result.add(time);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'headsign': headsign,
        'night': isNight,
        'from': formatClock(firstDeparture),
        'to': formatClock(lastDeparture),
        'every': everyMinutes,
      };
}

/// Public transport stop (mock data shaped after the ZTP Kraków GTFS feed).
class TransitStop {
  const TransitStop({
    required this.id,
    required this.name,
    required this.location,
    required this.lines,
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    return TransitStop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      lines: List<TransitLine>.unmodifiable(
        (json['lines'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TransitLine.fromJson),
      ),
    );
  }

  final String id;
  final String name;
  final LatLng location;
  final List<TransitLine> lines;

  bool get hasNightLines => lines.any((line) => line.isNight);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': location.latitude,
        'lng': location.longitude,
        'lines': [for (final line in lines) line.toJson()],
      };
}
