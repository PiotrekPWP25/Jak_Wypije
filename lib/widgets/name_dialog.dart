import 'package:flutter/material.dart';

import '../data/models/user_profile.dart';

/// Asks for the display name shown on Start and in the league.
class NameDialog extends StatefulWidget {
  const NameDialog({super.key, required this.initial});

  final String initial;

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jak masz na imię?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: UserProfile.maxNameLength,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Zapisz')),
      ],
    );
  }
}
