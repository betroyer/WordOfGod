import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bible_repository.dart';
import '../../services/ai_service.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({
    super.key,
    this.verseId,
    this.prompt,
    this.conversationId,
  });

  final int? verseId;
  final String? prompt;
  final int? conversationId;

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  int? _conversationId;
  VerseRef? _verse;
  List<AiMessage> _messages = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.verseId != null) {
      _verse = await ref.read(bibleRepositoryProvider).verseRefById(widget.verseId!);
    }
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId;
      _messages = await ref.read(aiRepositoryProvider).messages(_conversationId!);
    }
    setState(() {});
    if (widget.prompt != null) {
      _controller.text = widget.prompt!;
      await _send();
    }
  }

  Future<void> _send({String? preset}) async {
    final settings = ref.read(settingsProvider);
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _controller.clear();
    try {
      final repo = ref.read(aiRepositoryProvider);
      _conversationId ??= await repo.createConversation(
        _verse?.reference ?? text.substring(0, text.length.clamp(0, 40)),
      );
      await repo.addMessage(
        conversationId: _conversationId!,
        role: 'user',
        message: text,
      );
      final history = await repo.messages(_conversationId!);
      final reply = await ref.read(aiServiceProvider).complete(
            settings: settings,
            contextVerse: _verse,
            messages: [
              for (final m in history) {'role': m.role, 'content': m.message},
            ],
          );
      await repo.addMessage(
        conversationId: _conversationId!,
        role: 'assistant',
        message: reply,
      );
      _messages = await repo.messages(_conversationId!);
    } catch (e) {
      _error = e.toString().replaceFirst('Bad state: ', '');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final onlineAsync = ref.watch(isOnlineProvider);
    final online = onlineAsync.valueOrNull ?? true;
    final needsSetup = !settings.isAiReady;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bible Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Chip(
                avatar: Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: online ? Colors.green : Colors.orange,
                ),
                label: Text(online ? 'Online' : 'Offline'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/ai/history'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!online)
            MaterialBanner(
              content: const Text(
                'You are offline. Connect to the internet to use the AI Bible Assistant.',
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          if (needsSetup)
            MaterialBanner(
              content: const Text(
                'Add an AI API key in Settings. The assistant needs internet to reply.',
              ),
              actions: [
                TextButton(
                  onPressed: () => context.go('/settings'),
                  child: const Text('Settings'),
                ),
              ],
            ),
          if (_verse != null)
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(_verse!.reference),
              subtitle: Text(
                _verse!.verse.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Explain'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.explain),
                ),
                ActionChip(
                  label: const Text('Simply'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.simple),
                ),
                ActionChip(
                  label: const Text('Context'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.context),
                ),
                ActionChip(
                  label: const Text('Questions'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.questions),
                ),
                ActionChip(
                  label: const Text('Apply'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.apply),
                ),
                ActionChip(
                  label: const Text('Reflect'),
                  onPressed: (!online || needsSetup)
                      ? null
                      : () => _send(preset: AiPrompts.reflect),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _messages.length) {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Thinking...'),
                  );
                }
                final msg = _messages[i];
                final mine = msg.role == 'user';
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      color: mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.message),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: online && !needsSetup && !_busy,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: online
                            ? 'Ask anything about the Bible'
                            : 'Connect to the internet to ask AI',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed:
                        (!online || needsSetup || _busy) ? null : () => _send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              AppConstants.aiDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class AiHistoryScreen extends ConsumerWidget {
  const AiHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI conversations')),
      body: FutureBuilder(
        future: ref.read(aiRepositoryProvider).conversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No saved conversations yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                title: Text(item.title),
                onTap: () => context.push(
                  '/ai',
                  extra: {'conversationId': item.id},
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final controller = TextEditingController(text: item.title);
                        final title = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename conversation'),
                            content: TextField(controller: controller),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, controller.text),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (title != null && title.trim().isNotEmpty) {
                          await ref
                              .read(aiRepositoryProvider)
                              .rename(item.id, title.trim());
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref
                            .read(aiRepositoryProvider)
                            .deleteConversation(item.id);
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
