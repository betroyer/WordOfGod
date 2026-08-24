import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bible_repository.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SavedListScreen(
      title: 'Bookmarks',
      emptyTitle: 'No bookmarks yet',
      emptyMessage: 'Bookmark a verse from the Bible reader.',
      loader: () => ref.read(studyRepositoryProvider).bookmarks(),
      onDelete: (id) => ref.read(studyRepositoryProvider).deleteBookmark(id),
      idOf: (row) => (row.$1 as Bookmark).id,
      extraAction: (context, row) async {
        final bookmark = row.$1 as Bookmark;
        final controller = TextEditingController(text: bookmark.note ?? '');
        final note = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bookmark note'),
            content: TextField(controller: controller, maxLines: 4),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (note != null) {
          await ref
              .read(studyRepositoryProvider)
              .setBookmarkNote(bookmark.id, note);
        }
      },
    );
  }
}

class _SavedListScreen extends ConsumerStatefulWidget {
  const _SavedListScreen({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.loader,
    required this.onDelete,
    required this.idOf,
    this.extraAction,
  });

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final Future<List<(Object, VerseRef)>> Function() loader;
  final Future<void> Function(int id) onDelete;
  final int Function((Object, VerseRef) row) idOf;
  final Future<void> Function(BuildContext, (Object, VerseRef) row)? extraAction;

  @override
  ConsumerState<_SavedListScreen> createState() => _SavedListScreenState();
}

class _SavedListScreenState extends ConsumerState<_SavedListScreen> {
  late Future<List<(Object, VerseRef)>> _future = widget.loader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_border,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final row = items[i];
              final verse = row.$2;
              return ListTile(
                title: Text(verse.reference),
                subtitle: Text(
                  verse.verse.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => context.go(
                  '/bible/${verse.verse.bookId}/${verse.verse.chapter}?verse=${verse.verse.verse}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.extraAction != null)
                      IconButton(
                        icon: const Icon(Icons.note_alt_outlined),
                        onPressed: () async {
                          await widget.extraAction!(context, row);
                          setState(() => _future = widget.loader());
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await widget.onDelete(widget.idOf(row));
                        setState(() => _future = widget.loader());
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
