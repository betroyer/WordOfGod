import 'package:drift/drift.dart';

import '../database/app_database.dart';

class JournalRepository {
  JournalRepository(this.db);
  final AppDatabase db;

  Future<List<Reflection>> reflections() => (db.select(db.reflections)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<Reflection> reflectionById(int id) =>
      (db.select(db.reflections)..where((t) => t.id.equals(id))).getSingle();

  Future<int> addReflection({
    required String read,
    required String learned,
    required String spoke,
    required String apply,
    required String pray,
    int? verseId,
  }) {
    final now = DateTime.now();
    return db
        .into(db.reflections)
        .insert(
          ReflectionsCompanion.insert(
            read: read,
            learned: learned,
            spoke: spoke,
            apply: apply,
            pray: pray,
            verseId: Value(verseId),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateReflection(int id, {
    required String read,
    required String learned,
    required String spoke,
    required String apply,
    required String pray,
  }) {
    return (db.update(db.reflections)..where((t) => t.id.equals(id))).write(
      ReflectionsCompanion(
        read: Value(read),
        learned: Value(learned),
        spoke: Value(spoke),
        apply: Value(apply),
        pray: Value(pray),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteReflection(int id) =>
      (db.delete(db.reflections)..where((t) => t.id.equals(id))).go();

  Future<List<Prayer>> prayers() => (db.select(db.prayers)
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .get();

  Future<int> addPrayer({
    required String title,
    required String body,
    required String category,
    String status = 'Ongoing',
  }) {
    final now = DateTime.now();
    return db.into(db.prayers).insert(
          PrayersCompanion.insert(
            title: title,
            body: body,
            category: category,
            status: status,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updatePrayer(Prayer prayer) {
    return (db.update(db.prayers)..where((t) => t.id.equals(prayer.id))).write(
      PrayersCompanion(
        title: Value(prayer.title),
        body: Value(prayer.body),
        category: Value(prayer.category),
        status: Value(prayer.status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deletePrayer(int id) =>
      (db.delete(db.prayers)..where((t) => t.id.equals(id))).go();

  Future<List<DevotionalEntry>> devotionals() =>
      (db.select(db.devotionalEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<int> addDevotional(DevotionalEntriesCompanion entry) =>
      db.into(db.devotionalEntries).insert(entry);

  Future<void> updateDevotional(DevotionalEntry entry) {
    return (db.update(db.devotionalEntries)..where((t) => t.id.equals(entry.id)))
        .write(
          DevotionalEntriesCompanion(
            date: Value(entry.date),
            reference: Value(entry.reference),
            title: Value(entry.title),
            reflection: Value(entry.reflection),
            application: Value(entry.application),
            prayer: Value(entry.prayer),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> deleteDevotional(int id) =>
      (db.delete(db.devotionalEntries)..where((t) => t.id.equals(id))).go();
}
