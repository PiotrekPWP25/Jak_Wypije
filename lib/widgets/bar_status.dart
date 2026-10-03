import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/bar.dart';
import '../data/models/city_zone.dart';

enum BarStatus { regular, hiddenGem, crowded, inRoute }

BarStatus barStatusOf(Bar bar, {bool inRoute = false, CrowdLevel? crowd}) {
  if (inRoute) return BarStatus.inRoute;
  if (crowd == CrowdLevel.high) return BarStatus.crowded;
  return bar.isHiddenGem ? BarStatus.hiddenGem : BarStatus.regular;
}

extension BarStatusX on BarStatus {
  String get label => switch (this) {
        BarStatus.regular => 'Popularny bar',
        BarStatus.hiddenGem => 'Ukryta perełka',
        BarStatus.crowded => 'W tłoku',
        BarStatus.inRoute => 'W trasie',
      };

  Color get color => switch (this) {
        BarStatus.regular => AppColors.regular,
        BarStatus.hiddenGem => AppColors.amber,
        BarStatus.crowded => AppColors.coral,
        BarStatus.inRoute => AppColors.green,
      };

  IconData get icon => switch (this) {
        BarStatus.regular => Icons.local_bar,
        BarStatus.hiddenGem => Icons.diamond_outlined,
        BarStatus.crowded => Icons.groups,
        BarStatus.inRoute => Icons.route,
      };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final BarStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
