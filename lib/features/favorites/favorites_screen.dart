import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bible_repository.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  late Future<List<(Favorite, VerseRef)>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(studyRepositoryProvider).favorites();
  }

  void _reload() {
    setState(() {
      _future = ref.read(studyRepositoryProvider).favorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Mark a verse as a favorite from the Bible reader.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final favorite = items[i].$1;
              final verse = items[i].$2;
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref
                        .read(studyRepositoryProvider)
                        .deleteFavorite(favorite.id);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
