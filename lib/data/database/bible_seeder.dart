import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import 'app_database.dart';

class BibleSeeder {
  BibleSeeder(this.db);
  final AppDatabase db;

  /// Alternate names used in plans / UI vs the bundled KJV JSON.
  static const _aliases = <String, String>{
    'Psalm': 'Psalms',
    'Psalms': 'Psalms',
    'Song of Solomon': 'Song of Solomon',
    'Song of Songs': 'Song of Solomon',
    'Canticles': 'Song of Solomon',
  };

  Future<void> ensureSeeded() async {
    final verses = await db.verseCount();
    if (verses > 0) {
      // Recover plans if a previous run seeded verses but failed on plans.
      final plans = await db.select(db.readingPlans).get();
      if (plans.isEmpty) {
        final books = await db.select(db.bibleBooks).get();
        final bookIds = {for (final b in books) b.name: b.id};
        await _seedPlans(bookIds);
      }
      return;
    }

    // Incomplete failed seed: wipe Bible/plan tables and try again.
    final books = await db.select(db.bibleBooks).get();
    if (books.isNotEmpty) {
      await _clearBibleTables();
    }
    await seed();
  }

  Future<void> _clearBibleTables() async {
    await db.transaction(() async {
      await db.delete(db.readingPlanItems).go();
      await db.delete(db.readingPlans).go();
      await db.delete(db.bibleVerses).go();
      await db.delete(db.bibleChapters).go();
      await db.delete(db.bibleBooks).go();
    });
  }

  Future<void> seed() async {
    final raw = await rootBundle.loadString(AppConstants.bibleAsset);
    final List<dynamic> books = jsonDecode(raw) as List<dynamic>;

    await db.transaction(() async {
      final bookIds = <String, int>{};

      for (var i = 0; i < books.length; i++) {
        final book = books[i] as Map<String, dynamic>;
        final name = book['name'] as String;
        final abbrev = book['abbrev'] as String;
        final chapters = (book['chapters'] as List)
            .map((c) => (c as List).cast<dynamic>())
            .toList();
        final testament = i < 39 ? 0 : 1;

        final bookId = await db
            .into(db.bibleBooks)
            .insert(
              BibleBooksCompanion.insert(
                name: name,
                abbrev: abbrev,
                testament: testament,
                bookOrder: i + 1,
              ),
            );
        bookIds[name] = bookId;

        final verseRows = <BibleVersesCompanion>[];
        for (var c = 0; c < chapters.length; c++) {
          final verses = chapters[c];
          await db
              .into(db.bibleChapters)
              .insert(
                BibleChaptersCompanion.insert(
                  bookId: bookId,
                  chapter: c + 1,
                  verseCount: verses.length,
                ),
              );
          for (var v = 0; v < verses.length; v++) {
            verseRows.add(
              BibleVersesCompanion.insert(
                bookId: bookId,
                chapter: c + 1,
                verse: v + 1,
                content: verses[v].toString(),
              ),
            );
          }
        }

        for (var start = 0; start < verseRows.length; start += 400) {
          final end =
              start + 400 > verseRows.length ? verseRows.length : start + 400;
          await db.batch((b) {
            b.insertAll(db.bibleVerses, verseRows.sublist(start, end));
          });
        }
      }

      await _seedPlans(bookIds);
    });
  }

  int _requireBookId(Map<String, int> bookIds, String name) {
    final canonical = _aliases[name] ?? name;
    final id = bookIds[canonical] ?? bookIds[name];
    if (id == null) {
      throw StateError(
        'Bible book "$name" (canonical: "$canonical") was not found in the dataset.',
      );
    }
    return id;
  }

  Future<void> _seedPlans(Map<String, int> bookIds) async {
    Future<void> addPlan({
      required String name,
      required String description,
      required List<(String book, int chapter)> items,
    }) async {
      final planId = await db
          .into(db.readingPlans)
          .insert(
            ReadingPlansCompanion.insert(name: name, description: description),
          );
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await db
            .into(db.readingPlanItems)
            .insert(
              ReadingPlanItemsCompanion.insert(
                planId: planId,
                dayNumber: i + 1,
                bookId: _requireBookId(bookIds, item.$1),
                chapter: item.$2,
              ),
            );
      }
    }

    await addPlan(
      name: '7-Day Bible Reading Plan',
      description: 'A one-week introduction across Law, Psalms, and Gospel.',
      items: const [
        ('Genesis', 1),
        ('Genesis', 2),
        ('Psalms', 1),
        ('Psalms', 23),
        ('John', 1),
        ('John', 3),
        ('Matthew', 5),
      ],
    );

    final nt30 = <(String, int)>[
      ('Matthew', 5),
      ('Matthew', 6),
      ('Matthew', 7),
      ('Mark', 1),
      ('Luke', 2),
      ('Luke', 15),
      ('John', 1),
      ('John', 3),
      ('John', 14),
      ('John', 15),
      ('Acts', 2),
      ('Acts', 9),
      ('Romans', 8),
      ('Romans', 12),
      ('1 Corinthians', 13),
      ('2 Corinthians', 5),
      ('Galatians', 5),
      ('Ephesians', 2),
      ('Ephesians', 6),
      ('Philippians', 2),
      ('Philippians', 4),
      ('Colossians', 3),
      ('1 Thessalonians', 5),
      ('2 Timothy', 3),
      ('Hebrews', 11),
      ('James', 1),
      ('1 Peter', 1),
      ('1 John', 4),
      ('Jude', 1),
      ('Revelation', 21),
    ];
    await addPlan(
      name: '30-Day New Testament Plan',
      description: 'Thirty key New Testament chapters for a month of reading.',
      items: nt30,
    );

    await addPlan(
      name: 'Proverbs Plan',
      description: 'One chapter of Proverbs each day for 31 days.',
      items: [for (var i = 1; i <= 31; i++) ('Proverbs', i)],
    );

    await addPlan(
      name: 'Gospel of John Plan',
      description: 'Read the Gospel of John, one chapter a day.',
      items: [for (var i = 1; i <= 21; i++) ('John', i)],
    );

    final ntBooks = [
      'Matthew',
      'Mark',
      'Luke',
      'John',
      'Acts',
      'Romans',
      '1 Corinthians',
      '2 Corinthians',
      'Galatians',
      'Ephesians',
      'Philippians',
      'Colossians',
      '1 Thessalonians',
      '2 Thessalonians',
      '1 Timothy',
      '2 Timothy',
      'Titus',
      'Philemon',
      'Hebrews',
      'James',
      '1 Peter',
      '2 Peter',
      '1 John',
      '2 John',
      '3 John',
      'Jude',
      'Revelation',
    ];
    final ntItems = <(String, int)>[];
    for (final name in ntBooks) {
      final bookId = _requireBookId(bookIds, name);
      final chapters = await (db.select(db.bibleChapters)
            ..where((t) => t.bookId.equals(bookId)))
          .get();
      chapters.sort((a, b) => a.chapter.compareTo(b.chapter));
      for (final ch in chapters) {
        ntItems.add((name, ch.chapter));
      }
    }
    await addPlan(
      name: 'New Testament Plan',
      description: 'Read the entire New Testament, chapter by chapter.',
      items: ntItems,
    );

    final gospelItems = <(String, int)>[];
    for (final name in ['Matthew', 'Mark', 'Luke', 'John']) {
      final bookId = _requireBookId(bookIds, name);
      final chapters = await (db.select(db.bibleChapters)
            ..where((t) => t.bookId.equals(bookId)))
          .get();
      chapters.sort((a, b) => a.chapter.compareTo(b.chapter));
      for (final ch in chapters) {
        gospelItems.add((name, ch.chapter));
      }
    }
    await addPlan(
      name: 'Gospel Reading Plan',
      description: 'Read Matthew, Mark, Luke, and John in order.',
      items: gospelItems,
    );
  }
}
