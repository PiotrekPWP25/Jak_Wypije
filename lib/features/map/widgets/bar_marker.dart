import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BarMarker extends StatelessWidget {
  const BarMarker({
    super.key,
    required this.emoji,
    required this.color,
    required this.onTap,
    this.planIndex,
    this.selected = false,
  });

  final String emoji;
  final Color color;
  final VoidCallback onTap;

  /// Position in the evening plan (0-based), if the bar is planned.
  final int? planIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final index = planIndex;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.black87,
                width: selected ? 3 : 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          if (index != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amber, width: 2),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.userLocation,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
    );
  }
}
