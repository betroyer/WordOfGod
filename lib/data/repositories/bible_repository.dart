import 'package:drift/drift.dart';

import '../database/app_database.dart';

class VerseRef {
  VerseRef({required this.verse, required this.book});

  final BibleVerse verse;
  final BibleBook book;

  String get reference => '${book.name} ${verse.chapter}:${verse.verse}';
  String get chapterReference => '${book.name} ${verse.chapter}';
}

class BibleRepository {
  BibleRepository(this.db);
  final AppDatabase db;

  Future<List<BibleBook>> books({int? testament}) {
    final q = db.select(db.bibleBooks)
      ..orderBy([(t) => OrderingTerm.asc(t.bookOrder)]);
    if (testament != null) {
      q.where((t) => t.testament.equals(testament));
    }
    return q.get();
  }

  Future<BibleBook> bookById(int id) =>
      (db.select(db.bibleBooks)..where((t) => t.id.equals(id))).getSingle();

  Future<BibleBook?> bookByName(String name) {
    return (db.select(db.bibleBooks)
          ..where((t) => t.name.lower().equals(name.toLowerCase())))
        .getSingleOrNull();
  }

  Future<int> chapterCount(int bookId) async {
    final rows = await (db.select(db.bibleChapters)
          ..where((t) => t.bookId.equals(bookId)))
        .get();
    return rows.length;
  }

  Future<List<BibleChapter>> chapters(int bookId) {
    return (db.select(db.bibleChapters)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm.asc(t.chapter)]))
        .get();
  }

  Future<List<BibleVerse>> chapterVerses(int bookId, int chapter) =>
      db.versesInChapter(bookId, chapter);

  Future<VerseRef> verseRefById(int verseId) async {
    final verse = await (db.select(db.bibleVerses)
          ..where((t) => t.id.equals(verseId)))
        .getSingle();
    final book = await bookById(verse.bookId);
    return VerseRef(verse: verse, book: book);
  }

  Future<VerseRef?> verseAt(int bookId, int chapter, int verse) async {
    final row = await (db.select(db.bibleVerses)..where(
          (t) =>
              t.bookId.equals(bookId) &
              t.chapter.equals(chapter) &
              t.verse.equals(verse),
        ))
        .getSingleOrNull();
    if (row == null) return null;
    final book = await bookById(bookId);
    return VerseRef(verse: row, book: book);
  }

  Future<List<VerseRef>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final refHit = await _searchReference(trimmed);
    if (refHit != null) return refHit;

    final verses = await db.searchVerses(trimmed);
    final bookMap = {for (final b in await books()) b.id: b};
    return verses
        .map((v) => VerseRef(verse: v, book: bookMap[v.bookId]!))
        .toList();
  }

  Future<List<VerseRef>?> _searchReference(String query) async {
    final match = RegExp(
      r'^(\d?\s*[A-Za-z]+)\s+(\d+)(?::(\d+))?$',
    ).firstMatch(query.trim());
    if (match == null) return null;

    final bookQuery = match.group(1)!.trim().toLowerCase();
    final chapter = int.parse(match.group(2)!);
    final verseNo = match.group(3) != null ? int.parse(match.group(3)!) : null;

    final all = await books();
    BibleBook? book;
    for (final b in all) {
      if (b.name.toLowerCase() == bookQuery ||
          b.abbrev.toLowerCase() == bookQuery ||
          b.name.toLowerCase().replaceAll(' ', '') ==
              bookQuery.replaceAll(' ', '')) {
        book = b;
        break;
      }
    }
    book ??= all.where((b) => b.name.toLowerCase().startsWith(bookQuery)).firstOrNull;
    if (book == null) return null;

    if (verseNo != null) {
      final hit = await verseAt(book.id, chapter, verseNo);
      return hit == null ? [] : [hit];
    }
    final verses = await chapterVerses(book.id, chapter);
    return verses.map((v) => VerseRef(verse: v, book: book!)).toList();
  }

  Future<VerseRef> verseOfTheDay(DateTime day) async {
    final total = await db.verseCount();
    final seed = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final offset = (seed.abs() % total) + 1;
    final verse = await (db.select(db.bibleVerses)
          ..where((t) => t.id.equals(offset)))
        .getSingle();
    final book = await bookById(verse.bookId);
    return VerseRef(verse: verse, book: book);
  }
}
