import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudyHubScreen extends StatelessWidget {
  const StudyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.search, 'Search', 'Find words, phrases, and references', '/study/search'),
      _Item(Icons.bookmark_outline, 'Bookmarks', 'Saved verses', '/study/bookmarks'),
      _Item(Icons.favorite_outline, 'Favorites', 'Verses that mean the most', '/study/favorites'),
      _Item(Icons.highlight_outlined, 'Highlights', 'Faith, hope, love, and more', '/study/highlights'),
      _Item(Icons.notes_outlined, 'Notes', 'Personal notes on Scripture', '/study/notes'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(item.route),
          );
        },
      ),
    );
  }
}

class _Item {
  const _Item(this.icon, this.title, this.subtitle, this.route);
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
