import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/fundraiser.dart';
import '../../data/repositories/bar_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/bar_status.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fundraiser_card.dart';
import '../../widgets/section_header.dart';
import 'barobranie_providers.dart';

class FundraiserDetailScreen extends ConsumerStatefulWidget {
  const FundraiserDetailScreen({super.key, required this.fundraiserId});

  final String fundraiserId;

  @override
  ConsumerState<FundraiserDetailScreen> createState() =>
      _FundraiserDetailScreenState();
}

class _FundraiserDetailScreenState
    extends ConsumerState<FundraiserDetailScreen> {
  static const List<int> _amounts = [10, 20, 50, 100, 500];
  int _amount = 20;

  Future<void> _contribute(Fundraiser fundraiser) async {
    final closesFundraiser =
        !fundraiser.isSaved && fundraiser.raised + _amount >= fundraiser.goal;
    final amount = _amount;
    await ref
        .read(contributionsProvider.notifier)
        .contribute(fundraiser.id, amount.toDouble());
    if (!mounted) return;
    if (closesFundraiser) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Bar uratowany!'),
          content: const Text(
            'Twoja wpłata domknęła zbiórkę. Społeczność JakWypiję właśnie '
            'uratowała kolejne miejsce w Krakowie. Dziękujemy!',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Super!'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Dzięki za wsparcie: ${formatPln(amount, whole: true)}! '
          '+${amount ~/ 2} pkt',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fundraisersAsync = ref.watch(fundraisersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Barobranie')),
      body: AsyncValueView<List<Fundraiser>>(
        value: fundraisersAsync,
        data: (fundraisers) {
          final fundraiser = fundraisers
              .where((f) => f.id == widget.fundraiserId)
              .firstOrNull;
          if (fundraiser == null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Nie znaleziono zbiórki',
            );
          }
          return _buildBody(context, fundraiser);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Fundraiser fundraiser) {
    final theme = Theme.of(context);
    final bar = ref.watch(barByIdProvider(fundraiser.barId)).valueOrNull;
    final status = fundraiserStatusOf(fundraiser);
    final percent = (fundraiser.raised / fundraiser.goal * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(bar?.emoji ?? '🍺', style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bar?.name ?? '',
                style: theme.textTheme.titleMedium,
              ),
            ),
            StatusChip(status: status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          fundraiser.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FundraiserProgressBar(fundraiser: fundraiser),
        const SizedBox(height: 8),
        Text(
          '$percent% celu · ${fundraiser.backers} '
          '${pluralize(fundraiser.backers, 'osoba wsparła', 'osoby wsparły', 'osób wsparło')}'
          '${fundraiser.isSaved ? '' : ' · brakuje ${formatPln(fundraiser.remaining, whole: true)}'}',
          style: theme.textTheme.bodySmall,
        ),
        if (fundraiser.myContribution > 0) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.amber.withAlpha(40),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.amber),
              title: Text(
                'Twoje wsparcie: '
                '${formatPln(fundraiser.myContribution, whole: true)}',
              ),
            ),
          ),
        ],
        const SectionHeader(
          title: 'Historia',
          padding: EdgeInsets.only(top: 24, bottom: 8),
        ),
        Text(fundraiser.story, style: theme.textTheme.bodyLarge),
        if (fundraiser.rewards.isNotEmpty) ...[
          const SectionHeader(
            title: 'Nagrody',
            padding: EdgeInsets.only(top: 24, bottom: 8),
          ),
          for (final reward in fundraiser.rewards)
            _RewardTile(
              reward: reward,
              unlocked: fundraiser.myContribution >= reward.minAmount,
            ),
        ],
        const SizedBox(height: 24),
        if (fundraiser.isSaved)
          Card(
            color: AppColors.saved.withAlpha(40),
            margin: EdgeInsets.zero,
            child: const ListTile(
              leading: Icon(Icons.verified, color: AppColors.saved),
              title: Text('Ten bar został uratowany!'),
              subtitle: Text('Wpadnij i podziękuj osobiście – najlepiej '
                  'zamawiając coś przy barze.'),
            ),
          )
        else ...[
          Text(
            'Wesprzyj bar',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in _amounts)
                ChoiceChip(
                  label: Text(formatPln(amount, whole: true)),
                  selected: amount == _amount,
                  onSelected: (_) => setState(() => _amount = amount),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _contribute(fundraiser),
            icon: const Icon(Icons.volunteer_activism),
            label: Text('Wpłać ${formatPln(_amount, whole: true)}'),
          ),
          const SizedBox(height: 8),
          Text(
            'Wersja demonstracyjna – żadne pieniądze nie są pobierane.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
        if (bar != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/bar/${bar.id}'),
            icon: const Icon(Icons.storefront),
            label: const Text('Zobacz bar'),
          ),
        ],
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.unlocked});

  final Reward reward;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        unlocked ? Icons.check_circle : Icons.card_giftcard,
        color: unlocked ? AppColors.saved : AppColors.amber,
      ),
      title: Text(reward.title),
      subtitle: Text(reward.description),
      trailing: Text('od ${formatPln(reward.minAmount, whole: true)}'),
    );
  }
}
