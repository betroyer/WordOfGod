import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';

class PrayersScreen extends ConsumerWidget {
  const PrayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/prayer/edit'),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: ref.read(journalRepositoryProvider).prayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: 'No prayers yet',
              message: 'Keep an offline journal of ongoing and answered prayers.',
              actionLabel: 'Add prayer',
              onAction: () => context.push('/prayer/edit'),
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
                  '${item.category} · ${item.status} · ${DateFormat.yMMMd().format(item.createdAt)}\n${item.body}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () => context.push('/prayer/edit', extra: {'id': item.id}),
              );
            },
          );
        },
      ),
    );
  }
}

class PrayerEditorScreen extends ConsumerStatefulWidget {
  const PrayerEditorScreen({super.key, this.prayerId});
  final int? prayerId;

  @override
  ConsumerState<PrayerEditorScreen> createState() => _PrayerEditorScreenState();
}

class _PrayerEditorScreenState extends ConsumerState<PrayerEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = AppConstants.prayerCategories.first;
  String _status = AppConstants.prayerStatuses.first;
  Prayer? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.prayerId == null) return;
    final all = await ref.read(journalRepositoryProvider).prayers();
    final item = all.where((p) => p.id == widget.prayerId).firstOrNull;
    if (item == null) return;
    _existing = item;
    _title.text = item.title;
    _body.text = item.body;
    _category = item.category;
    _status = item.status;
    setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New prayer' : 'Edit prayer'),
        actions: [
          if (_existing != null)
            IconButton(
              onPressed: () async {
                await ref.read(journalRepositoryProvider).deletePrayer(_existing!.id);
                if (context.mounted) context.pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(
            onPressed: () async {
              if (_title.text.trim().isEmpty) return;
              if (_existing == null) {
                await ref.read(journalRepositoryProvider).addPrayer(
                      title: _title.text.trim(),
                      body: _body.text.trim(),
                      category: _category,
                      status: _status,
                    );
              } else {
                await ref.read(journalRepositoryProvider).updatePrayer(
                      _existing!.copyWith(
                        title: _title.text.trim(),
                        body: _body.text.trim(),
                        category: _category,
                        status: _status,
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
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final c in AppConstants.prayerCategories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            items: [
              for (final c in AppConstants.prayerStatuses)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _status = v ?? _status),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Prayer', alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
