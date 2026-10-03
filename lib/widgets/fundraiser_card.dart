import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/models/bar.dart';
import '../data/models/fundraiser.dart';
import 'bar_status.dart';

class FundraiserCard extends StatelessWidget {
  const FundraiserCard({
    super.key,
    required this.fundraiser,
    required this.onTap,
    this.bar,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final Fundraiser fundraiser;
  final Bar? bar;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final venue = bar;
    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    venue?.emoji ?? '🍺',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fundraiser.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (venue != null)
                          Text(
                            '${venue.name} · ${venue.district}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: fundraiserStatusOf(fundraiser)),
                ],
              ),
              const SizedBox(height: 12),
              FundraiserProgressBar(fundraiser: fundraiser),
            ],
          ),
        ),
      ),
    );
  }
}

class FundraiserProgressBar extends StatelessWidget {
  const FundraiserProgressBar({super.key, required this.fundraiser});

  final Fundraiser fundraiser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = fundraiserStatusOf(fundraiser).color;
    final days = fundraiser.daysLeft(DateTime.now());
    final String deadlineText;
    if (fundraiser.isSaved) {
      deadlineText = 'Uratowany!';
    } else if (days > 0) {
      deadlineText = 'jeszcze $days ${pluralize(days, 'dzień', 'dni', 'dni')}';
    } else {
      deadlineText = 'ostatni dzień';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fundraiser.progress,
            minHeight: 8,
            color: color,
            backgroundColor: color.withAlpha(50),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatPln(fundraiser.raised, whole: true)} z '
                '${formatPln(fundraiser.goal, whole: true)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              deadlineText,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
