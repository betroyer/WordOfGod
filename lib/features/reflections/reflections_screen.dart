import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';

class ReflectionsScreen extends ConsumerWidget {
  const ReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflections')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/reflection/edit'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: ref.read(journalRepositoryProvider).reflections(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.psychology_outlined,
              title: 'Start a reflection',
              message: 'Capture what you read, learned, and want to apply.',
              actionLabel: 'New reflection',
              onAction: () => context.push('/reflection/edit'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.read.isEmpty ? 'Reflection' : item.read),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(item.createdAt)}\n${item.learned}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () => context.push('/reflection/edit', extra: {'id': item.id}),
              );
            },
          );
        },
      ),
    );
  }
}

class ReflectionEditorScreen extends ConsumerStatefulWidget {
  const ReflectionEditorScreen({super.key, this.reflectionId, this.verseId});

  final int? reflectionId;
  final int? verseId;

  @override
  ConsumerState<ReflectionEditorScreen> createState() =>
      _ReflectionEditorScreenState();
}

class _ReflectionEditorScreenState extends ConsumerState<ReflectionEditorScreen> {
  final _read = TextEditingController();
  final _learned = TextEditingController();
  final _spoke = TextEditingController();
  final _apply = TextEditingController();
  final _pray = TextEditingController();
  Reflection? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.verseId != null) {
      final verse = await ref.read(bibleRepositoryProvider).verseRefById(widget.verseId!);
      _read.text = verse.reference;
    }
    if (widget.reflectionId != null) {
      final item =
          await ref.read(journalRepositoryProvider).reflectionById(widget.reflectionId!);
      _existing = item;
      _read.text = item.read;
      _learned.text = item.learned;
      _spoke.text = item.spoke;
      _apply.text = item.apply;
      _pray.text = item.pray;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _read.dispose();
    _learned.dispose();
    _spoke.dispose();
    _apply.dispose();
    _pray.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New reflection' : 'Edit reflection'),
        actions: [
          if (_existing != null)
            IconButton(
              onPressed: () async {
                await ref.read(journalRepositoryProvider).deleteReflection(_existing!.id);
                if (context.mounted) context.pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: () async {
              if (_existing == null) {
                await ref.read(journalRepositoryProvider).addReflection(
                      read: _read.text.trim(),
                      learned: _learned.text.trim(),
                      spoke: _spoke.text.trim(),
                      apply: _apply.text.trim(),
                      pray: _pray.text.trim(),
                      verseId: widget.verseId,
                    );
              } else {
                await ref.read(journalRepositoryProvider).updateReflection(
                      _existing!.id,
                      read: _read.text.trim(),
                      learned: _learned.text.trim(),
                      spoke: _spoke.text.trim(),
                      apply: _apply.text.trim(),
                      pray: _pray.text.trim(),
                    );
              }
              if (context.mounted) context.pop();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_read, 'What did you read?'),
          _field(_learned, 'What did you learn?'),
          _field(_spoke, 'What spoke to you?'),
          _field(_apply, 'How can you apply it?'),
          _field(_pray, 'What do you want to pray about?'),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: 4,
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      ),
    );
  }
}
