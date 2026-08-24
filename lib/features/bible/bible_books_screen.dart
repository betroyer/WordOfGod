import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';

final booksProvider = FutureProvider.family<List<BibleBook>, int?>((ref, testament) {
  return ref.watch(bibleRepositoryProvider).books(testament: testament);
});

class BibleBooksScreen extends ConsumerStatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  ConsumerState<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends ConsumerState<BibleBooksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible'),
        actions: [
          IconButton(
            onPressed: () => context.go('/study/search'),
            icon: const Icon(Icons.search),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.goldSoft,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'Old Testament'),
            Tab(text: 'New Testament'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _BookList(testament: 0),
          _BookList(testament: 1),
        ],
      ),
    );
  }
}

class _BookList extends ConsumerWidget {
  const _BookList({required this.testament});
  final int testament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider(testament));
    return books.when(
      data: (items) => ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final book = items[i];
          return ListTile(
            title: Text(book.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final chapters =
                  await ref.read(bibleRepositoryProvider).chapterCount(book.id);
              if (!context.mounted) return;
              if (chapters == 1) {
                context.go('/bible/${book.id}/1');
                return;
              }
              final chapter = await showModalBottomSheet<int>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: chapters,
                    itemBuilder: (context, index) {
                      final n = index + 1;
                      return FilledButton.tonal(
                        onPressed: () => Navigator.pop(context, n),
                        child: Text('$n'),
                      );
                    },
                  );
                },
              );
              if (chapter != null && context.mounted) {
                context.go('/bible/${book.id}/$chapter');
              }
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
