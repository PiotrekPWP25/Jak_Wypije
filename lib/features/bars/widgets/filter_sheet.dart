import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/price_range.dart';
import '../bar_filters.dart';

/// Booking-style filter sheet. Returns the new filters, or `null` if closed.
Future<BarFilters?> showBarFilterSheet(
  BuildContext context, {
  required BarFilters initial,
  required List<BarListing> listings,
  required String distanceFrom,
}) {
  return showModalBottomSheet<BarFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(
      initial: initial,
      listings: listings,
      distanceFrom: distanceFrom,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.listings,
    required this.distanceFrom,
  });

  final BarFilters initial;
  final List<BarListing> listings;
  final String distanceFrom;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late BarFilters _filters = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultCount = applyFilters(widget.listings, _filters).length;
    final distance = _filters.maxDistanceMeters;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Filtry', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _filters = _filters.cleared()),
                  child: const Text('Wyczyść'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _SectionTitle('Odległość od: ${widget.distanceFrom}'),
                Slider(
                  value: distance ?? BarFilters.distanceBound,
                  min: 250,
                  max: BarFilters.distanceBound,
                  divisions: 19,
                  label: distance == null
                      ? 'dowolna'
                      : 'do ${formatDistance(distance)}',
                  onChanged: (value) => setState(
                    () => _filters = _filters.copyWith(
                      maxDistanceMeters:
                          value >= BarFilters.distanceBound ? null : value,
                    ),
                  ),
                ),
                Text(
                  distance == null
                      ? 'Dowolna odległość'
                      : 'Do ${formatDistance(distance)} '
                          '(ok. ${formatDuration((distance / 80).ceil())} pieszo)',
                  style: theme.textTheme.bodySmall,
                ),
                _PriceSlider(
                  title: '🍺 Piwo 0,5 l',
                  bounds: BarFilters.beerBounds,
                  value: _filters.beer,
                  onChanged: (range) =>
                      setState(() => _filters = _filters.copyWith(beer: range)),
                ),
                _PriceSlider(
                  title: '🥃 Shot',
                  bounds: BarFilters.shotBounds,
                  value: _filters.shot,
                  onChanged: (range) =>
                      setState(() => _filters = _filters.copyWith(shot: range)),
                ),
                _PriceSlider(
                  title: '🍹 Drink',
                  bounds: BarFilters.drinkBounds,
                  value: _filters.drink,
                  onChanged: (range) => setState(
                    () => _filters = _filters.copyWith(drink: range),
                  ),
                ),
                _PriceSlider(
                  title: '🍽️ Jedzenie (na osobę)',
                  bounds: BarFilters.foodBounds,
                  value: _filters.food,
                  onChanged: (range) =>
                      setState(() => _filters = _filters.copyWith(food: range)),
                ),
                const _SectionTitle('Udogodnienia'),
                _Toggle(
                  title: 'Płatność kartą',
                  icon: Icons.credit_card,
                  value: _filters.acceptsCards,
                  onChanged: (v) => setState(
                      () => _filters = _filters.copyWith(acceptsCards: v)),
                ),
                _Toggle(
                  title: 'Kuchnia do późna (22:00+)',
                  icon: Icons.restaurant,
                  value: _filters.lateKitchen,
                  onChanged: (v) => setState(
                      () => _filters = _filters.copyWith(lateKitchen: v)),
                ),
                _Toggle(
                  title: 'Bez barier (wejście i toaleta)',
                  icon: Icons.accessible,
                  value: _filters.barrierFree,
                  onChanged: (v) => setState(
                      () => _filters = _filters.copyWith(barrierFree: v)),
                ),
                _Toggle(
                  title: 'Otwarte teraz',
                  icon: Icons.schedule,
                  value: _filters.openNow,
                  onChanged: (v) =>
                      setState(() => _filters = _filters.copyWith(openNow: v)),
                ),
                _Toggle(
                  title: 'Poza tłokiem (strefy bez tłumów)',
                  icon: Icons.eco_outlined,
                  value: _filters.offPeak,
                  onChanged: (v) =>
                      setState(() => _filters = _filters.copyWith(offPeak: v)),
                ),
                _Toggle(
                  title: 'Opcje bezalkoholowe (0%, lemoniady)',
                  icon: Icons.local_drink_outlined,
                  value: _filters.nonAlcoholic,
                  onChanged: (v) => setState(
                    () => _filters = _filters.copyWith(nonAlcoholic: v),
                  ),
                ),
                _Toggle(
                  title: 'Happy hour teraz',
                  icon: Icons.local_offer_outlined,
                  value: _filters.happyHourNow,
                  onChanged: (v) => setState(
                    () => _filters = _filters.copyWith(happyHourNow: v),
                  ),
                ),
                _Toggle(
                  title: 'Nowe miejsca',
                  icon: Icons.fiber_new_outlined,
                  value: _filters.onlyNew,
                  onChanged: (v) =>
                      setState(() => _filters = _filters.copyWith(onlyNew: v)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_filters),
                  child: Text(
                    'Pokaż $resultCount '
                    '${pluralize(resultCount, 'bar', 'bary', 'barów')}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _PriceSlider extends StatelessWidget {
  const _PriceSlider({
    required this.title,
    required this.bounds,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final PriceRange bounds;
  final PriceRange? value;
  final ValueChanged<PriceRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value ?? bounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        Row(
          children: [
            Expanded(
              child: RangeSlider(
                values: RangeValues(current.min, current.max),
                min: bounds.min,
                max: bounds.max,
                divisions: (bounds.max - bounds.min).round(),
                labels: RangeLabels(
                  formatPln(current.min, whole: true),
                  formatPln(current.max, whole: true),
                ),
                onChanged: (range) {
                  final isFull =
                      range.start <= bounds.min && range.end >= bounds.max;
                  onChanged(
                    isFull
                        ? null
                        : PriceRange(min: range.start, max: range.end),
                  );
                },
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                value == null ? 'dowolnie' : current.label,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
