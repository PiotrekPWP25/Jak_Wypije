import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/bar.dart';
import '../data/models/fundraiser.dart';

enum BarStatus { regular, hiddenGem, rescuing, saved }

BarStatus barStatusOf(Bar bar, Fundraiser? fundraiser) {
  if (fundraiser != null) {
    return fundraiser.isSaved ? BarStatus.saved : BarStatus.rescuing;
  }
  return bar.isHiddenGem ? BarStatus.hiddenGem : BarStatus.regular;
}

BarStatus fundraiserStatusOf(Fundraiser fundraiser) =>
    fundraiser.isSaved ? BarStatus.saved : BarStatus.rescuing;

extension BarStatusX on BarStatus {
  String get label => switch (this) {
        BarStatus.regular => 'Popularny bar',
        BarStatus.hiddenGem => 'Ukryta perełka',
        BarStatus.rescuing => 'Ratowany',
        BarStatus.saved => 'Uratowany',
      };

  Color get color => switch (this) {
        BarStatus.regular => AppColors.regular,
        BarStatus.hiddenGem => AppColors.amber,
        BarStatus.rescuing => AppColors.rescuing,
        BarStatus.saved => AppColors.saved,
      };

  IconData get icon => switch (this) {
        BarStatus.regular => Icons.local_bar,
        BarStatus.hiddenGem => Icons.diamond_outlined,
        BarStatus.rescuing => Icons.sos,
        BarStatus.saved => Icons.verified,
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
