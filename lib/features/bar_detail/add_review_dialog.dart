import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

typedef ReviewDraft = ({int rating, String comment});

class AddReviewDialog extends StatefulWidget {
  const AddReviewDialog({super.key, required this.barName});

  final String barName;

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Oceń: ${widget.barName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  tooltip: '$i/5',
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Co polecasz? (opcjonalnie)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<ReviewDraft>(
            (rating: _rating, comment: _controller.text),
          ),
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}
