import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  /// 0–5, halves are rendered as half stars.
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star
                : rating >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: AppColors.amber,
          ),
      ],
    );
  }
}
