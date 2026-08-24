import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: FutureBuilder(
        future: ref.read(studyRepositoryProvider).allNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notes_outlined,
              title: 'No notes yet',
              message: 'Add a note to any verse from the Bible reader.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final note = items[i].$1;
              final verse = items[i].$2;
              return ListTile(
                title: Text(verse.reference),
                subtitle: Text(note.body, maxLines: 3, overflow: TextOverflow.ellipsis),
                onTap: () => context.push(
                  '/note/edit',
                  extra: {'verseId': verse.verse.id, 'noteId': note.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.verseId, this.noteId});

  final int verseId;
  final int? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _controller = TextEditingController();
  Note? _note;
  String _reference = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final verse = await ref.read(bibleRepositoryProvider).verseRefById(widget.verseId);
    Note? note;
    if (widget.noteId != null) {
      final notes = await ref.read(studyRepositoryProvider).notesForVerse(widget.verseId);
      note = notes.where((n) => n.id == widget.noteId).firstOrNull;
      if (note != null) _controller.text = note.body;
    }
    setState(() {
      _reference = verse.reference;
      _note = note;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note == null ? 'Add note' : 'Edit note'),
        actions: [
          if (_note != null)
            IconButton(
              onPressed: () async {
                await ref.read(studyRepositoryProvider).deleteNote(_note!.id);
                if (context.mounted) context.pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: () async {
              final body = _controller.text.trim();
              if (body.isEmpty) return;
              if (_note == null) {
                await ref.read(studyRepositoryProvider).addNote(widget.verseId, body);
              } else {
                await ref.read(studyRepositoryProvider).updateNote(_note!.id, body);
              }
              if (context.mounted) context.pop();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_reference, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: 'Write your note...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
