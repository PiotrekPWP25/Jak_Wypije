import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_value_view.dart';
import '../../widgets/empty_state.dart';
import 'bar_filters.dart';
import 'bars_providers.dart';
import 'widgets/bar_card.dart';
import 'widgets/filter_sheet.dart';

extension _BarSortLabel on BarSort {
  String get label => switch (this) {
        BarSort.friends => 'Ocena znajomych',
        BarSort.distance => 'Najbliżej',
        BarSort.beerPrice => 'Najtańsze piwo',
      };
}

extension _ReferenceLabel on DistanceReference {
  String get label => switch (this) {
        DistanceReference.lastStop => 'Od poprzedniego baru w trasie',
        DistanceReference.me => 'Od mojej lokalizacji',
        DistanceReference.center => 'Od Rynku Głównego',
      };
}

class BarsScreen extends ConsumerStatefulWidget {
  const BarsScreen({super.key});

  @override
  ConsumerState<BarsScreen> createState() => _BarsScreenState();
}

class _BarsScreenState extends ConsumerState<BarsScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(barFiltersProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final listings = ref.read(barListingsProvider).valueOrNull;
    if (listings == null) return;
    final result = await showBarFilterSheet(
      context,
      initial: ref.read(barFiltersProvider),
      listings: listings,
      distanceFrom: ref.read(referencePointProvider).label,
    );
    if (result != null) {
      ref.read(barFiltersProvider.notifier).update(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(barFiltersProvider);
    final reference = ref.watch(referencePointProvider);
    final mode = ref.watch(distanceReferenceProvider);
    final results = ref.watch(filteredListingsProvider);
    final notifier = ref.read(barFiltersProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Bary')),
      body: AsyncValueView<List<BarListing>>(
        value: results,
        data: (listings) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) =>
                      notifier.update(filters.copyWith(query: value)),
                  decoration: InputDecoration(
                    hintText: 'Szukaj baru, dzielnicy, klimatu…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide:
                          BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide:
                          BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<DistanceReference>(
                        initialValue: mode,
                        onSelected: (value) => ref
                            .read(distanceReferenceProvider.notifier)
                            .set(value),
                        itemBuilder: (context) => [
                          for (final option in DistanceReference.values)
                            PopupMenuItem(
                              value: option,
                              child: Text(option.label),
                            ),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.place_outlined, size: 18),
                          label: Text(
                            'Odległość od: ${reference.label}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune),
                      label: Text(
                        filters.activeCount == 0
                            ? 'Filtry'
                            : 'Filtry (${filters.activeCount})',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    for (final sort in BarSort.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sort.label),
                          selected: filters.sort == sort,
                          onSelected: (_) =>
                              notifier.update(filters.copyWith(sort: sort)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text(
                  filters.sort == BarSort.friends
                      ? '${listings.length} wyników · najpierw ocena '
                          'znajomych, potem ocena ogólna'
                      : '${listings.length} wyników',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (listings.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'Brak barów dla tych filtrów',
                  message: 'Poszerz zakres cen albo odległość.',
                  action: OutlinedButton(
                    onPressed: notifier.clear,
                    child: const Text('Wyczyść filtry'),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: listings.length,
                itemBuilder: (context, index) => BarCard(
                  listing: listings[index],
                  fromLabel: reference.label,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
