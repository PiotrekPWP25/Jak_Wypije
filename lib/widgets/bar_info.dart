import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/bar.dart';
import '../data/models/city_zone.dart';

String formatRating(double rating) =>
    rating.toStringAsFixed(1).replaceAll('.', ',');

/// "✨ Nowe", "🥤 Opcje 0%", "🕒 Happy hour 17:00–19:00" badges.
class BarBadges extends StatelessWidget {
  const BarBadges({super.key, required this.bar, this.happyNow = false});

  final Bar bar;

  /// Highlights the happy hour when it is running right now.
  final bool happyNow;

  @override
  Widget build(BuildContext context) {
    final happy = bar.happyHour;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (bar.isNew) const _Badge(text: '✨ Nowe', color: AppColors.amber),
        if (bar.nonAlcoholic)
          const _Badge(text: '🥤 Opcje 0%', color: AppColors.green),
        if (happy != null)
          _Badge(
            text: happyNow
                ? '🕒 Teraz: ${happy.label}'
                : '🕒 ${happy.hours} ${happy.label}',
            color: happyNow ? AppColors.coral : AppColors.night,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

extension CrowdLevelX on CrowdLevel {
  String get label => switch (this) {
        CrowdLevel.low => 'Luźno',
        CrowdLevel.medium => 'Średnio',
        CrowdLevel.high => 'Tłok',
      };

  Color get color => switch (this) {
        CrowdLevel.low => AppColors.green,
        CrowdLevel.medium => AppColors.amber,
        CrowdLevel.high => AppColors.coral,
      };
}

class CrowdBadge extends StatelessWidget {
  const CrowdBadge({super.key, required this.level});

  final CrowdLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: level.color.withAlpha(36),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups, size: 14, color: level.color),
          const SizedBox(width: 4),
          Text(
            level.label,
            style: TextStyle(
              color: level.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Booking-style score square for the friends' rating.
class FriendsScoreBadge extends StatelessWidget {
  const FriendsScoreBadge({
    super.key,
    required this.rating,
    required this.count,
    this.compact = false,
  });

  final double? rating;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = rating;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: value == null
                ? theme.colorScheme.surfaceContainerHighest
                : AppColors.brown,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            value == null ? '–' : formatRating(value),
            style: TextStyle(
              color: value == null
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.amber,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 13 : 15,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value == null ? 'Brak ocen znajomych' : 'Znajomi ($count)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class PublicRatingText extends StatelessWidget {
  const PublicRatingText({super.key, required this.bar});

  final Bar bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          'Ogólnie ${formatRating(bar.publicRating)} · '
          '${bar.publicRatingCount} opinii',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// `🍺 12–16 zł · 🥃 8–12 zł · …` as small chips.
class PriceChips extends StatelessWidget {
  const PriceChips({super.key, required this.bar});

  final Bar bar;

  @override
  Widget build(BuildContext context) {
    final shot = bar.shot;
    final drink = bar.drink;
    final food = bar.food;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _PriceChip(emoji: '🍺', label: bar.beer.label),
        if (shot != null) _PriceChip(emoji: '🥃', label: shot.label),
        if (drink != null) _PriceChip(emoji: '🍹', label: drink.label),
        _PriceChip(
          emoji: '🍽️',
          label: food == null ? 'bez kuchni' : food.label,
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$emoji $label',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Small icons: barrier-free, card payments, late kitchen.
class AmenityIcons extends StatelessWidget {
  const AmenityIcons({super.key, required this.bar});

  final Bar bar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget icon(IconData data, String tooltip, {bool active = true}) => Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              data,
              size: 18,
              color: active ? color : color.withAlpha(70),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bar.accessibility.isBarrierFree)
          icon(Icons.accessible, 'Bez barier'),
        icon(
          bar.acceptsCards ? Icons.credit_card : Icons.money,
          bar.acceptsCards ? 'Płatność kartą' : 'Tylko gotówka',
        ),
        if (bar.hasLateKitchen) icon(Icons.restaurant, 'Kuchnia do późna'),
        if (bar.accessibility.quietArea)
          icon(Icons.volume_down, 'Cicha strefa'),
      ],
    );
  }
}

/// The logo mark (mug with the map pin) in a rounded cream tile.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/images/logo_mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
