import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'bible_repository.dart';

class StudyRepository {
  StudyRepository(this.db, this.bible);
  final AppDatabase db;
  final BibleRepository bible;

  Future<bool> isBookmarked(int verseId) async {
    final row = await (db.select(db.bookmarks)
          ..where((t) => t.verseId.equals(verseId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> toggleBookmark(int verseId) async {
    final existing = await (db.select(db.bookmarks)
          ..where((t) => t.verseId.equals(verseId)))
        .getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.bookmarks)
          .insert(
            BookmarksCompanion.insert(verseId: verseId, createdAt: DateTime.now()),
          );
    } else {
      await (db.delete(db.bookmarks)..where((t) => t.id.equals(existing.id))).go();
    }
  }

  Future<void> setBookmarkNote(int bookmarkId, String? note) {
    return (db.update(db.bookmarks)..where((t) => t.id.equals(bookmarkId))).write(
      BookmarksCompanion(note: Value(note)),
    );
  }

  Future<void> deleteBookmark(int id) =>
      (db.delete(db.bookmarks)..where((t) => t.id.equals(id))).go();

  Future<List<(Bookmark, VerseRef)>> bookmarks() async {
    final rows = await (db.select(db.bookmarks)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final out = <(Bookmark, VerseRef)>[];
    for (final row in rows) {
      out.add((row, await bible.verseRefById(row.verseId)));
    }
    return out;
  }

  Future<bool> isFavorite(int verseId) async {
    final row = await (db.select(db.favorites)
          ..where((t) => t.verseId.equals(verseId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> toggleFavorite(int verseId) async {
    final existing = await (db.select(db.favorites)
          ..where((t) => t.verseId.equals(verseId)))
        .getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.favorites)
          .insert(
            FavoritesCompanion.insert(verseId: verseId, createdAt: DateTime.now()),
          );
    } else {
      await (db.delete(db.favorites)..where((t) => t.id.equals(existing.id))).go();
    }
  }

  Future<void> deleteFavorite(int id) =>
      (db.delete(db.favorites)..where((t) => t.id.equals(id))).go();

  Future<List<(Favorite, VerseRef)>> favorites() async {
    final rows = await (db.select(db.favorites)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final out = <(Favorite, VerseRef)>[];
    for (final row in rows) {
      out.add((row, await bible.verseRefById(row.verseId)));
    }
    return out;
  }

  Future<Highlight?> highlightFor(int verseId) {
    return (db.select(db.highlights)
          ..where((t) => t.verseId.equals(verseId)))
        .getSingleOrNull();
  }

  Future<void> setHighlight(int verseId, String category) async {
    final now = DateTime.now();
    final existing = await highlightFor(verseId);
    if (existing == null) {
      await db
          .into(db.highlights)
          .insert(
            HighlightsCompanion.insert(
              verseId: verseId,
              category: category,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (db.update(db.highlights)..where((t) => t.id.equals(existing.id)))
          .write(
            HighlightsCompanion(category: Value(category), updatedAt: Value(now)),
          );
    }
  }

  Future<void> deleteHighlight(int id) =>
      (db.delete(db.highlights)..where((t) => t.id.equals(id))).go();

  Future<List<(Highlight, VerseRef)>> highlights({String? category}) async {
    final q = db.select(db.highlights)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (category != null) q.where((t) => t.category.equals(category));
    final rows = await q.get();
    final out = <(Highlight, VerseRef)>[];
    for (final row in rows) {
      out.add((row, await bible.verseRefById(row.verseId)));
    }
    return out;
  }

  Future<List<Note>> notesForVerse(int verseId) {
    return (db.select(db.notes)
          ..where((t) => t.verseId.equals(verseId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<int> addNote(int verseId, String body) {
    final now = DateTime.now();
    return db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            verseId: verseId,
            body: body,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateNote(int id, String body) {
    return (db.update(db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(body: Value(body), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteNote(int id) =>
      (db.delete(db.notes)..where((t) => t.id.equals(id))).go();

  Future<List<(Note, VerseRef)>> allNotes() async {
    final rows = await (db.select(db.notes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    final out = <(Note, VerseRef)>[];
    for (final row in rows) {
      out.add((row, await bible.verseRefById(row.verseId)));
    }
    return out;
  }
}
