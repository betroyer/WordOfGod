import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/database/app_database.dart';
import '../../services/ai_service.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.highlightVerse,
  });

  final int bookId;
  final int chapter;
  final int? highlightVerse;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  BibleBook? _book;
  List<BibleVerse> _verses = [];
  Map<int, Highlight> _highlights = {};
  Set<int> _favorites = {};
  Set<int> _bookmarks = {};
  bool _read = false;
  int? _selectedVerseId;
  final _keys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant BibleReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.chapter != widget.chapter) {
      _load();
    }
  }

  Future<void> _load() async {
    final bible = ref.read(bibleRepositoryProvider);
    final study = ref.read(studyRepositoryProvider);
    final progress = ref.read(progressRepositoryProvider);
    final book = await bible.bookById(widget.bookId);
    final verses = await bible.chapterVerses(widget.bookId, widget.chapter);
    final highlights = <int, Highlight>{};
    final favorites = <int>{};
    final bookmarks = <int>{};
    for (final v in verses) {
      final h = await study.highlightFor(v.id);
      if (h != null) highlights[v.id] = h;
      if (await study.isFavorite(v.id)) favorites.add(v.id);
      if (await study.isBookmarked(v.id)) bookmarks.add(v.id);
    }
    final read =
        await progress.isChapterRead(widget.bookId, widget.chapter);
    final settings = ref.read(settingsProvider);
    await ref.read(settingsProvider.notifier).update(
          settings.copyWith(
            lastBookId: widget.bookId,
            lastChapter: widget.chapter,
          ),
        );
    if (!mounted) return;
    setState(() {
      _book = book;
      _verses = verses;
      _highlights = highlights;
      _favorites = favorites;
      _bookmarks = bookmarks;
      _read = read;
      for (final v in verses) {
        _keys[v.id] = GlobalKey();
      }
    });
    final target = widget.highlightVerse;
    if (target != null) {
      final verse = verses.where((v) => v.verse == target).firstOrNull;
      if (verse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _keys[verse.id]?.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 400),
              alignment: 0.2,
            );
          }
        });
      }
    }
  }

  Future<void> _openActions(BibleVerse verse) async {
    setState(() => _selectedVerseId = verse.id);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _VerseActions(
        bookName: _book?.name ?? '',
        verse: verse,
        isFavorite: _favorites.contains(verse.id),
        isBookmarked: _bookmarks.contains(verse.id),
        highlight: _highlights[verse.id],
        onChanged: _load,
      ),
    );
    if (mounted) setState(() => _selectedVerseId = null);
    await _load();
  }

  Future<void> _turn(int delta) async {
    final bible = ref.read(bibleRepositoryProvider);
    final count = await bible.chapterCount(widget.bookId);
    var chapter = widget.chapter + delta;
    var bookId = widget.bookId;
    if (chapter < 1) {
      if (bookId <= 1) return;
      bookId -= 1;
      chapter = await bible.chapterCount(bookId);
    } else if (chapter > count) {
      if (bookId >= 66) return;
      bookId += 1;
      chapter = 1;
    }
    if (!mounted) return;
    context.go('/bible/$bookId/$chapter');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final title = _book == null
        ? 'Reader'
        : chapterRef(_book!.name, widget.chapter);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _read ? 'Chapter read' : 'Mark chapter read',
            onPressed: () async {
              await ref.read(progressRepositoryProvider).markChapterRead(
                    widget.bookId,
                    widget.chapter,
                  );
              setState(() => _read = true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapter marked as read')),
                );
              }
            },
            icon: Icon(_read ? Icons.check_circle : Icons.check_circle_outline),
          ),
          IconButton(
            onPressed: () => context.push('/ai'),
            icon: const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      body: _verses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _verses.length,
              itemBuilder: (context, i) {
                final verse = _verses[i];
                final highlight = _highlights[verse.id];
                final selected = _selectedVerseId == verse.id;
                final color = highlight == null
                    ? null
                    : Color(HighlightLooks.colors[highlight.category] ??
                        AppColors.gold.toARGB32());
                return KeyedSubtree(
                  key: _keys[verse.id],
                  child: InkWell(
                    onTap: () => _openActions(verse),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold.withValues(alpha: 0.18)
                            : color?.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${verse.verse}  ',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: settings.fontSize - 2,
                              ),
                            ),
                            TextSpan(text: verse.content),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: settings.fontSize,
                          height: settings.lineSpacing,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => _turn(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Smaller text',
                      onPressed: () => ref.read(settingsProvider.notifier).update(
                            settings.copyWith(
                              fontSize: (settings.fontSize - 1).clamp(14, 32),
                            ),
                          ),
                      icon: const Icon(Icons.text_decrease),
                    ),
                    IconButton(
                      tooltip: 'Larger text',
                      onPressed: () => ref.read(settingsProvider.notifier).update(
                            settings.copyWith(
                              fontSize: (settings.fontSize + 1).clamp(14, 32),
                            ),
                          ),
                      icon: const Icon(Icons.text_increase),
                    ),
                    IconButton(
                      tooltip: 'Line spacing',
                      onPressed: () => ref.read(settingsProvider.notifier).update(
                            settings.copyWith(
                              lineSpacing:
                                  settings.lineSpacing >= 2.0 ? 1.4 : settings.lineSpacing + 0.2,
                            ),
                          ),
                      icon: const Icon(Icons.format_line_spacing),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _turn(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseActions extends ConsumerWidget {
  const _VerseActions({
    required this.bookName,
    required this.verse,
    required this.isFavorite,
    required this.isBookmarked,
    required this.highlight,
    required this.onChanged,
  });

  final String bookName;
  final BibleVerse verse;
  final bool isFavorite;
  final bool isBookmarked;
  final Highlight? highlight;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.read(studyRepositoryProvider);
    final refText = verseRef(bookName, verse.chapter, verse.verse);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(refText, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(verse.content, maxLines: 4, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
              label: const Text('Favorite'),
              onPressed: () async {
                await study.toggleFavorite(verse.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ActionChip(
              avatar: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              ),
              label: const Text('Bookmark'),
              onPressed: () async {
                await study.toggleBookmark(verse.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.note_add_outlined),
              label: const Text('Add Note'),
              onPressed: () {
                Navigator.pop(context);
                context.push('/note/edit', extra: {'verseId': verse.id});
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: '$refText — ${verse.content}'),
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(text: '$refText — ${verse.content}'),
                );
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.auto_awesome),
              label: const Text('Ask AI'),
              onPressed: () {
                Navigator.pop(context);
                _askAi(context, verse.id);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Highlight', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final cat in AppConstants.highlightCategories)
              ChoiceChip(
                selected: highlight?.category == cat,
                label: Text(cat),
                selectedColor: Color(
                  HighlightLooks.colors[cat] ?? AppColors.gold.toARGB32(),
                ).withValues(alpha: 0.35),
                onSelected: (_) async {
                  await study.setHighlight(verse.id, cat);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ],
    );
  }

  void _askAi(BuildContext context, int verseId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Explain this verse'),
            onTap: () => _go(context, verseId, AiPrompts.explain),
          ),
          ListTile(
            title: const Text('Explain simply'),
            onTap: () => _go(context, verseId, AiPrompts.simple),
          ),
          ListTile(
            title: const Text('Give me context'),
            onTap: () => _go(context, verseId, AiPrompts.context),
          ),
          ListTile(
            title: const Text('Study questions'),
            onTap: () => _go(context, verseId, AiPrompts.questions),
          ),
          ListTile(
            title: const Text('How can I apply this?'),
            onTap: () => _go(context, verseId, AiPrompts.apply),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int verseId, String prompt) {
    Navigator.pop(context);
    context.push('/ai', extra: {'verseId': verseId, 'prompt': prompt});
  }
}
