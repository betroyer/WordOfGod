import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';

class DevotionalsScreen extends ConsumerWidget {
  const DevotionalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devotional Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/devotional/edit'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: ref.read(journalRepositoryProvider).devotionals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'No devotionals yet',
              message: 'Write longer entries with Scripture, reflection, and prayer.',
              actionLabel: 'New entry',
              onAction: () => context.push('/devotional/edit'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(item.date)} · ${item.reference}',
                ),
                onTap: () =>
                    context.push('/devotional/edit', extra: {'id': item.id}),
              );
            },
          );
        },
      ),
    );
  }
}

class DevotionalEditorScreen extends ConsumerStatefulWidget {
  const DevotionalEditorScreen({super.key, this.entryId});
  final int? entryId;

  @override
  ConsumerState<DevotionalEditorScreen> createState() =>
      _DevotionalEditorScreenState();
}

class _DevotionalEditorScreenState extends ConsumerState<DevotionalEditorScreen> {
  final _title = TextEditingController();
  final _reference = TextEditingController();
  final _reflection = TextEditingController();
  final _application = TextEditingController();
  final _prayer = TextEditingController();
  DateTime _date = DateTime.now();
  DevotionalEntry? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.entryId == null) return;
    final all = await ref.read(journalRepositoryProvider).devotionals();
    final item = all.where((e) => e.id == widget.entryId).firstOrNull;
    if (item == null) return;
    _existing = item;
    _title.text = item.title;
    _reference.text = item.reference;
    _reflection.text = item.reflection;
    _application.text = item.application;
    _prayer.text = item.prayer;
    _date = item.date;
    setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _reference.dispose();
    _reflection.dispose();
    _application.dispose();
    _prayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New devotional' : 'Edit devotional'),
        actions: [
          if (_existing != null)
            IconButton(
              onPressed: () async {
                await ref
                    .read(journalRepositoryProvider)
                    .deleteDevotional(_existing!.id);
                if (context.mounted) context.pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: () async {
              final now = DateTime.now();
              if (_existing == null) {
                await ref.read(journalRepositoryProvider).addDevotional(
                      DevotionalEntriesCompanion.insert(
                        date: _date,
                        reference: _reference.text.trim(),
                        title: _title.text.trim(),
                        reflection: _reflection.text.trim(),
                        application: _application.text.trim(),
                        prayer: _prayer.text.trim(),
                        createdAt: now,
                        updatedAt: now,
                      ),
                    );
              } else {
                await ref.read(journalRepositoryProvider).updateDevotional(
                      _existing!.copyWith(
                        date: _date,
                        reference: _reference.text.trim(),
                        title: _title.text.trim(),
                        reflection: _reflection.text.trim(),
                        application: _application.text.trim(),
                        prayer: _prayer.text.trim(),
                      ),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMEd().format(_date)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          TextField(
            controller: _reference,
            decoration: const InputDecoration(labelText: 'Bible reference'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflection,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Reflection'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _application,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Application'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prayer,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Prayer'),
          ),
        ],
      ),
    );
  }
}
