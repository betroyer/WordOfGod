import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/bible_repository.dart';

final searchResultsProvider =
    FutureProvider.family<List<VerseRef>, String>((ref, query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(bibleRepositoryProvider).search(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Word, phrase, or John 3:16',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: results.when(
              data: (items) {
                if (_query.trim().isEmpty) {
                  return const EmptyState(
                    icon: Icons.search,
                    title: 'Offline Bible search',
                    message:
                        'Search the local KJV for words, phrases, or references. No internet needed.',
                  );
                }
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try another word or a reference like Psalm 23:1.',
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(item.reference),
                      subtitle: Text(
                        item.verse.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => context.go(
                        '/bible/${item.verse.bookId}/${item.verse.chapter}?verse=${item.verse.verse}',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}
