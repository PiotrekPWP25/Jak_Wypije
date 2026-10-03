import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/bar.dart';
import '../../data/models/fundraiser.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/fundraiser_card.dart';
import '../../widgets/section_header.dart';
import 'barobranie_providers.dart';

class BarobranieScreen extends ConsumerWidget {
  const BarobranieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundraisersAsync = ref.watch(fundraisersProvider);
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    final barsById = {for (final bar in bars) bar.id: bar};

    return Scaffold(
      appBar: AppBar(title: const Text('Barobranie')),
      body: AsyncValueView<List<Fundraiser>>(
        value: fundraisersAsync,
        data: (fundraisers) {
          final rescuing = fundraisers.where((f) => !f.isSaved).toList()
            ..sort((a, b) => a.deadline.compareTo(b.deadline));
          final saved = fundraisers.where((f) => f.isSaved).toList();
          final totalRaised =
              fundraisers.fold<double>(0.0, (sum, f) => sum + f.raised);
          final totalBackers =
              fundraisers.fold<int>(0, (sum, f) => sum + f.backers);

          Widget card(Fundraiser fundraiser) => FundraiserCard(
                fundraiser: fundraiser,
                bar: barsById[fundraiser.barId],
                onTap: () => context.push('/fundraiser/${fundraiser.id}'),
              );

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _IntroCard(
                totalRaised: totalRaised,
                totalBackers: totalBackers,
                savedCount: saved.length,
              ),
              if (rescuing.isNotEmpty) ...[
                const SectionHeader(title: 'Ratowane teraz'),
                for (final fundraiser in rescuing) card(fundraiser),
              ],
              if (saved.isNotEmpty) ...[
                const SectionHeader(title: 'Uratowane przez społeczność'),
                for (final fundraiser in saved) card(fundraiser),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.totalRaised,
    required this.totalBackers,
    required this.savedCount,
  });

  final double totalRaised;
  final int totalBackers;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ulubiony bar ma kłopoty? Zrzućmy się!',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Barobranie to zbiórki społeczności na bary zagrożone '
              'zamknięciem. Wspierasz lokalne miejsca, a w zamian dostajesz '
              'nagrody i punkty w JakWypiję.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: formatPln(totalRaised, whole: true),
                    label: 'zebrano',
                    color: AppColors.amber,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: '$totalBackers',
                    label: 'wspierających',
                    color: AppColors.amber,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: '$savedCount',
                    label: pluralize(
                      savedCount,
                      'uratowany bar',
                      'uratowane bary',
                      'uratowanych barów',
                    ),
                    color: AppColors.saved,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
