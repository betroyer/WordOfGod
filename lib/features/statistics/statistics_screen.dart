import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/section_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Progress')),
      body: FutureBuilder(
        future: ref.read(progressRepositoryProvider).stats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          final tiles = [
            ('Chapters read', '${s.chaptersRead} / ${s.totalChapters}'),
            ('Overall Bible progress', '${(s.overallProgress * 100).toStringAsFixed(1)}%'),
            ('Books completed', '${s.booksCompleted}'),
            ('Reading sessions', '${s.sessions}'),
            ('Current streak', '${s.currentStreak} days'),
            ('Longest streak', '${s.longestStreak} days'),
            ('Favorite book', s.favoriteBookName),
            ('Bookmarked verses', '${s.bookmarkCount}'),
            ('Plans completed', '${s.planCompletions}'),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LinearProgressIndicator(value: s.overallProgress),
              const SizedBox(height: 16),
              for (final tile in tiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(tile.$1)),
                        Text(
                          tile.$2,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
