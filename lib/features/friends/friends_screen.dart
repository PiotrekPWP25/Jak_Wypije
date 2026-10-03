import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/bar.dart';
import '../../data/models/friend.dart';
import '../../data/models/review.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/section_header.dart';
import '../profile/profile_providers.dart';
import 'reviews_controller.dart';

typedef _RankEntry = ({String name, String emoji, int points, bool isMe});

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final reviews =
        ref.watch(allReviewsProvider).valueOrNull ?? const <Review>[];
    final bars = ref.watch(barsProvider).valueOrNull ?? const <Bar>[];
    final myName = ref.watch(userNameProvider);
    final myPoints = ref.watch(profileStatsProvider).points;

    return Scaffold(
      appBar: AppBar(title: const Text('Znajomi')),
      body: AsyncValueView<List<Friend>>(
        value: friendsAsync,
        data: (friends) {
          final barsById = {for (final bar in bars) bar.id: bar};
          final friendsById = {for (final friend in friends) friend.id: friend};
          final ranking = <_RankEntry>[
            for (final friend in friends)
              (
                name: friend.name,
                emoji: friend.emoji,
                points: friend.points,
                isMe: false,
              ),
            (name: myName, emoji: '🍺', points: myPoints, isMe: true),
          ]..sort((a, b) => b.points.compareTo(a.points));
          final friendReviews =
              reviews.where((review) => !review.isMine).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SectionHeader(title: 'Ranking odkrywców'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final (index, entry) in ranking.indexed)
                      _RankTile(position: index + 1, entry: entry),
                  ],
                ),
              ),
              const SectionHeader(title: 'Ostatnie oceny znajomych'),
              for (final review in friendReviews)
                Builder(
                  builder: (context) {
                    final author = resolveAuthor(review, friendsById, myName);
                    return ReviewTile(
                      review: review,
                      authorName: author.name,
                      authorEmoji: author.emoji,
                      barName: barsById[review.barId]?.name,
                      onTap: () => context.push('/bar/${review.barId}'),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.position, required this.entry});

  final int position;
  final _RankEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$position.',
    };
    return ListTile(
      tileColor: entry.isMe ? AppColors.amber.withAlpha(30) : null,
      leading: SizedBox(
        width: 32,
        child: Center(
          child: Text(medal, style: const TextStyle(fontSize: 20)),
        ),
      ),
      title: Text(
        '${entry.emoji} ${entry.name}${entry.isMe ? ' (Ty)' : ''}',
        style: entry.isMe
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      trailing: Text(
        '${entry.points} pkt',
        style: theme.textTheme.titleSmall?.copyWith(color: AppColors.amber),
      ),
    );
  }
}
