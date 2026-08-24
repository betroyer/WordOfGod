import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JournalHubScreen extends StatelessWidget {
  const JournalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Reflections'),
            subtitle: const Text('What did you read, learn, and apply?'),
            onTap: () => context.go('/journal/reflections'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Prayer Journal'),
            subtitle: const Text('Ongoing and answered prayers'),
            onTap: () => context.go('/journal/prayers'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Devotional Journal'),
            subtitle: const Text('Longer entries with Scripture and application'),
            onTap: () => context.go('/journal/devotionals'),
          ),
        ],
      ),
    );
  }
}
