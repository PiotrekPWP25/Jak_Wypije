import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../data/models/review.dart';
import 'rating_stars.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    required this.authorName,
    required this.authorEmoji,
    this.barName,
    this.onTap,
  });

  final Review review;
  final String authorName;
  final String authorEmoji;

  /// When set, the tile reads "Ola o Zgubiony Kapsel".
  final String? barName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barName = this.barName;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(authorEmoji)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              barName == null ? authorName : '$authorName o: $barName',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          RatingStars(rating: review.rating.toDouble(), size: 14),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.comment.isNotEmpty) Text(review.comment),
          Text(
            formatShortDate(review.createdAt),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
