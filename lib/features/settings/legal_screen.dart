import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_value_view.dart';

enum LegalDoc {
  terms('Regulamin', 'assets/legal/regulamin.md'),
  privacy('Polityka prywatności', 'assets/legal/polityka_prywatnosci.md');

  const LegalDoc(this.title, this.asset);

  final String title;
  final String asset;

  static LegalDoc? byName(String name) =>
      values.where((doc) => doc.name == name).firstOrNull;
}

enum LegalBlockType { heading, subheading, bullet, paragraph }

typedef LegalBlock = ({LegalBlockType type, String text});

/// Tiny Markdown subset used by `assets/legal/*.md`: `#`/`##` headings,
/// `- ` bullets and paragraphs (consecutive lines are joined). `**` is
/// dropped – no Markdown package needed.
List<LegalBlock> parseLegalDoc(String source) {
  final blocks = <LegalBlock>[];
  final paragraph = <String>[];

  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add((type: LegalBlockType.paragraph, text: paragraph.join(' ')));
    paragraph.clear();
  }

  for (final raw in source.split('\n')) {
    final line = raw.trim().replaceAll('**', '');
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('## ')) {
      flush();
      blocks.add((type: LegalBlockType.subheading, text: line.substring(3)));
    } else if (line.startsWith('# ')) {
      flush();
      blocks.add((type: LegalBlockType.heading, text: line.substring(2)));
    } else if (line.startsWith('- ')) {
      flush();
      blocks.add((type: LegalBlockType.bullet, text: line.substring(2)));
    } else {
      paragraph.add(line);
    }
  }
  flush();
  return blocks;
}

final _legalDocProvider = FutureProvider.family<List<LegalBlock>, LegalDoc>(
  (ref, doc) async => parseLegalDoc(await rootBundle.loadString(doc.asset)),
);

class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: AsyncValueView(
        value: ref.watch(_legalDocProvider(doc)),
        data: (blocks) => SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              for (final block in blocks)
                switch (block.type) {
                  LegalBlockType.heading => Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        block.text,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  LegalBlockType.subheading => Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: Text(
                        block.text,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  LegalBlockType.bullet => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(block.text)),
                        ],
                      ),
                    ),
                  LegalBlockType.paragraph => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(block.text),
                    ),
                },
            ],
          ),
        ),
      ),
    );
  }
}
