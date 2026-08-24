import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/section_card.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/progress_repository.dart';

final dailyVerseProvider = FutureProvider<VerseRef>((ref) {
  return ref.watch(bibleRepositoryProvider).verseOfTheDay(DateTime.now());
});

final homeStatsProvider = FutureProvider<ReadingStats>((ref) {
  return ref.watch(progressRepositoryProvider).stats();
});

final latestReflectionProvider = FutureProvider<dynamic>((ref) async {
  final items = await ref.watch(journalRepositoryProvider).reflections();
  return items.isEmpty ? null : items.first;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final verse = ref.watch(dailyVerseProvider);
    final stats = ref.watch(homeStatsProvider);
    final reflection = ref.watch(latestReflectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Ask AI',
            onPressed: () => context.push('/ai'),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            greetingFor(DateTime.now()),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ready to spend some time in God's Word?",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: 20),
          verse.when(
            data: (v) => SectionCard(
              onTap: () => context.go(
                '/bible/${v.verse.bookId}/${v.verse.chapter}?verse=${v.verse.verse}',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VERSE OF THE DAY',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    v.reference,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${v.verse.content}"',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            loading: () => const SectionCard(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SectionCard(child: Text('$e')),
          ),
          const SizedBox(height: 12),
          SectionCard(
            onTap: () {
              if (settings.lastBookId != null && settings.lastChapter != null) {
                context.go('/bible/${settings.lastBookId}/${settings.lastChapter}');
              } else {
                context.go('/bible');
              }
            },
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: AppColors.navy),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Continue Reading'),
                      Text(
                        settings.lastBookId == null
                            ? 'Open the Bible'
                            : 'Pick up where you left off',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          reflection.when(
            data: (item) => SectionCard(
              onTap: () => context.go('/journal/reflections'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Reflection"),
                  const SizedBox(height: 6),
                  Text(
                    item == null
                        ? 'What did you learn from today\'s reading?'
                        : item.learned as String,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          stats.when(
            data: (s) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatMini(
                        label: 'Progress',
                        value:
                            '${(s.overallProgress * 100).toStringAsFixed(1)}%',
                        onTap: () => context.go('/home/stats'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMini(
                        label: 'Streak',
                        value: '${s.currentStreak} days',
                        onTap: () => context.go('/home/stats'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  onTap: () => context.go('/home/plans'),
                  child: const Row(
                    children: [
                      Icon(Icons.flag_outlined),
                      SizedBox(width: 12),
                      Expanded(child: Text('Reading Plans')),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
