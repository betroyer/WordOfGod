import 'package:drift/drift.dart';

import '../../core/utils/formatters.dart';
import '../database/app_database.dart';

class ReadingStats {
  ReadingStats({
    required this.chaptersRead,
    required this.booksCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.sessions,
    required this.favoriteBookName,
    required this.bookmarkCount,
    required this.totalChapters,
    required this.planCompletions,
  });

  final int chaptersRead;
  final int booksCompleted;
  final int currentStreak;
  final int longestStreak;
  final int sessions;
  final String favoriteBookName;
  final int bookmarkCount;
  final int totalChapters;
  final int planCompletions;

  double get overallProgress =>
      totalChapters == 0 ? 0 : chaptersRead / totalChapters;
}

class ProgressRepository {
  ProgressRepository(this.db);
  final AppDatabase db;

  Future<void> markChapterRead(int bookId, int chapter) async {
    final now = DateTime.now();
    final existing = await (db.select(db.readingProgress)..where(
          (t) => t.bookId.equals(bookId) & t.chapter.equals(chapter),
        ))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.readingProgress).insert(
            ReadingProgressCompanion.insert(
              bookId: bookId,
              chapter: chapter,
              readAt: now,
            ),
          );
    } else {
      await (db.update(db.readingProgress)..where((t) => t.id.equals(existing.id)))
          .write(ReadingProgressCompanion(readAt: Value(now)));
    }
    await db.into(db.readingHistory).insert(
          ReadingHistoryCompanion.insert(
            bookId: bookId,
            chapter: chapter,
            startedAt: now,
          ),
        );
    await _syncPlanItems(bookId, chapter);
  }

  Future<bool> isChapterRead(int bookId, int chapter) async {
    final row = await (db.select(db.readingProgress)..where(
          (t) => t.bookId.equals(bookId) & t.chapter.equals(chapter),
        ))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> _syncPlanItems(int bookId, int chapter) async {
    final items = await (db.select(db.readingPlanItems)..where(
          (t) => t.bookId.equals(bookId) & t.chapter.equals(chapter),
        ))
        .get();
    for (final item in items) {
      await (db.update(db.readingPlanItems)..where((t) => t.id.equals(item.id)))
          .write(const ReadingPlanItemsCompanion(completed: Value(true)));
      await _refreshPlanStatus(item.planId);
    }
  }

  Future<void> _refreshPlanStatus(int planId) async {
    final items = await (db.select(db.readingPlanItems)
          ..where((t) => t.planId.equals(planId)))
        .get();
    final done = items.where((i) => i.completed).length;
    if (done == items.length && items.isNotEmpty) {
      await (db.update(db.readingPlans)..where((t) => t.id.equals(planId)))
          .write(
            ReadingPlansCompanion(
              status: const Value('completed'),
              completedAt: Value(DateTime.now()),
            ),
          );
    }
  }

  Future<List<ReadingPlan>> plans() => (db.select(db.readingPlans)
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();

  Future<ReadingPlan> planById(int id) =>
      (db.select(db.readingPlans)..where((t) => t.id.equals(id))).getSingle();

  Future<List<ReadingPlanItem>> planItems(int planId) {
    return (db.select(db.readingPlanItems)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.dayNumber)]))
        .get();
  }

  Future<void> startPlan(int planId) {
    return (db.update(db.readingPlans)..where((t) => t.id.equals(planId))).write(
      ReadingPlansCompanion(
        status: const Value('active'),
        startedAt: Value(DateTime.now()),
        completedAt: const Value(null),
      ),
    );
  }

  Future<void> pausePlan(int planId) {
    return (db.update(db.readingPlans)..where((t) => t.id.equals(planId))).write(
      const ReadingPlansCompanion(status: Value('paused')),
    );
  }

  Future<void> resumePlan(int planId) {
    return (db.update(db.readingPlans)..where((t) => t.id.equals(planId))).write(
      const ReadingPlansCompanion(status: Value('active')),
    );
  }

  Future<void> resetPlan(int planId) async {
    await (db.update(db.readingPlanItems)..where((t) => t.planId.equals(planId)))
        .write(const ReadingPlanItemsCompanion(completed: Value(false)));
    await (db.update(db.readingPlans)..where((t) => t.id.equals(planId))).write(
      const ReadingPlansCompanion(
        status: Value('idle'),
        startedAt: Value(null),
        completedAt: Value(null),
      ),
    );
  }

  Future<void> togglePlanItem(ReadingPlanItem item) async {
    await (db.update(db.readingPlanItems)..where((t) => t.id.equals(item.id)))
        .write(ReadingPlanItemsCompanion(completed: Value(!item.completed)));
    if (!item.completed) {
      await markChapterRead(item.bookId, item.chapter);
    }
    await _refreshPlanStatus(item.planId);
  }

  Future<ReadingStats> stats() async {
    final progress = await db.select(db.readingProgress).get();
    final history = await db.select(db.readingHistory).get();
    final chapters = await db.select(db.bibleChapters).get();
    final books = await db.select(db.bibleBooks).get();
    final bookmarks = await db.select(db.bookmarks).get();
    final plans = await db.select(db.readingPlans).get();

    final byBook = <int, int>{};
    for (final p in progress) {
      byBook[p.bookId] = (byBook[p.bookId] ?? 0) + 1;
    }
    var booksCompleted = 0;
    for (final book in books) {
      final total = chapters.where((c) => c.bookId == book.id).length;
      if (total > 0 && (byBook[book.id] ?? 0) >= total) booksCompleted++;
    }

    String favorite = '—';
    if (byBook.isNotEmpty) {
      final topId = byBook.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      favorite = books.firstWhere((b) => b.id == topId).name;
    }

    final days = history.map((h) => ymd(h.startedAt)).toSet().toList()..sort();
    final streaks = _streaks(days);

    return ReadingStats(
      chaptersRead: progress.length,
      booksCompleted: booksCompleted,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      sessions: history.length,
      favoriteBookName: favorite,
      bookmarkCount: bookmarks.length,
      totalChapters: chapters.length,
      planCompletions: plans.where((p) => p.status == 'completed').length,
    );
  }

  (int current, int longest) _streaks(List<String> sortedDays) {
    if (sortedDays.isEmpty) return (0, 0);
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sortedDays.length; i++) {
      final prev = DateTime.parse(sortedDays[i - 1]);
      final cur = DateTime.parse(sortedDays[i]);
      if (cur.difference(prev).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    final today = dateOnly(DateTime.now());
    final last = DateTime.parse(sortedDays.last);
    final gap = today.difference(dateOnly(last)).inDays;
    final current = (gap <= 1) ? run : 0;
    return (current, longest);
  }
}
