import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BibleBooks,
    BibleChapters,
    BibleVerses,
    Bookmarks,
    Favorites,
    Highlights,
    Notes,
    Reflections,
    Prayers,
    DevotionalEntries,
    ReadingPlans,
    ReadingPlanItems,
    ReadingProgress,
    ReadingHistory,
    AiConversations,
    AiMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'faithpath'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_verses_book_chapter ON bible_verses (book_id, chapter)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_verses_ref ON bible_verses (book_id, chapter, verse)',
          );
        },
      );

  Future<int> verseCount() async {
    final count = countAll();
    final query = selectOnly(bibleVerses)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<BibleVerse> verseByRef(int bookId, int chapter, int verse) {
    return (select(bibleVerses)
          ..where(
            (t) =>
                t.bookId.equals(bookId) &
                t.chapter.equals(chapter) &
                t.verse.equals(verse),
          ))
        .getSingle();
  }

  Future<List<BibleVerse>> versesInChapter(int bookId, int chapter) {
    return (select(bibleVerses)
          ..where((t) => t.bookId.equals(bookId) & t.chapter.equals(chapter))
          ..orderBy([(t) => OrderingTerm.asc(t.verse)]))
        .get();
  }

  Future<List<BibleVerse>> searchVerses(String query, {int limit = 80}) {
    final like = '%${query.replaceAll('%', '')}%';
    return (select(bibleVerses)
          ..where((t) => t.content.like(like))
          ..limit(limit))
        .get();
  }

  Future<void> resetUserData() async {
    await transaction(() async {
      await delete(aiMessages).go();
      await delete(aiConversations).go();
      await delete(bookmarks).go();
      await delete(favorites).go();
      await delete(highlights).go();
      await delete(notes).go();
      await delete(reflections).go();
      await delete(prayers).go();
      await delete(devotionalEntries).go();
      await delete(readingProgress).go();
      await delete(readingHistory).go();
      await (update(readingPlanItems)..where((t) => t.id.isBiggerThanValue(0)))
          .write(const ReadingPlanItemsCompanion(completed: Value(false)));
      await (update(readingPlans)..where((t) => t.id.isBiggerThanValue(0))).write(
        const ReadingPlansCompanion(
          status: Value('idle'),
          startedAt: Value(null),
          completedAt: Value(null),
        ),
      );
    });
  }
}
