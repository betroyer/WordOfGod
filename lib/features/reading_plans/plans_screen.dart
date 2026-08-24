import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/database/app_database.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Plans')),
      body: FutureBuilder(
        future: ref.read(progressRepositoryProvider).plans(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data!;
          return ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final plan = plans[i];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text('${plan.description}\nStatus: ${plan.status}'),
                isThreeLine: true,
                onTap: () => context.go('/home/plans/${plan.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final int planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  ReadingPlan? _plan;
  List<ReadingPlanItem> _items = [];
  Map<int, BibleBook> _books = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = ref.read(progressRepositoryProvider);
    final bible = ref.read(bibleRepositoryProvider);
    final plan = await progress.planById(widget.planId);
    final items = await progress.planItems(widget.planId);
    final books = {for (final b in await bible.books()) b.id: b};
    setState(() {
      _plan = plan;
      _items = items;
      _books = books;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (plan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final done = _items.where((i) => i.completed).length;
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.description),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _items.isEmpty ? 0 : done / _items.length,
                ),
                const SizedBox(height: 8),
                Text('$done / ${_items.length} chapters · ${plan.status}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (plan.status == 'idle' || plan.status == 'paused')
                      FilledButton(
                        onPressed: () async {
                          if (plan.status == 'paused') {
                            await ref
                                .read(progressRepositoryProvider)
                                .resumePlan(plan.id);
                          } else {
                            await ref
                                .read(progressRepositoryProvider)
                                .startPlan(plan.id);
                          }
                          await _load();
                        },
                        child: Text(plan.status == 'paused' ? 'Resume' : 'Start'),
                      ),
                    if (plan.status == 'active')
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(progressRepositoryProvider)
                              .pausePlan(plan.id);
                          await _load();
                        },
                        child: const Text('Pause'),
                      ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(progressRepositoryProvider)
                            .resetPlan(plan.id);
                        await _load();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final book = _books[item.bookId];
                return CheckboxListTile(
                  value: item.completed,
                  title: Text('Day ${item.dayNumber}'),
                  subtitle: Text('${book?.name ?? ''} ${item.chapter}'),
                  onChanged: (_) async {
                    await ref
                        .read(progressRepositoryProvider)
                        .togglePlanItem(item);
                    await _load();
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.menu_book_outlined),
                    onPressed: () =>
                        context.go('/bible/${item.bookId}/${item.chapter}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
