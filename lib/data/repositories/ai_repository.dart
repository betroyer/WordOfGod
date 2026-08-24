import 'package:drift/drift.dart';

import '../database/app_database.dart';

class AiRepository {
  AiRepository(this.db);
  final AppDatabase db;

  Future<List<AiConversation>> conversations() =>
      (db.select(db.aiConversations)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<AiConversation> conversation(int id) =>
      (db.select(db.aiConversations)..where((t) => t.id.equals(id))).getSingle();

  Future<List<AiMessage>> messages(int conversationId) =>
      (db.select(db.aiMessages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> createConversation(String title) {
    final now = DateTime.now();
    return db.into(db.aiConversations).insert(
          AiConversationsCompanion.insert(
            title: title,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> rename(int id, String title) {
    return (db.update(db.aiConversations)..where((t) => t.id.equals(id))).write(
      AiConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConversation(int id) async {
    await (db.delete(db.aiMessages)
          ..where((t) => t.conversationId.equals(id)))
        .go();
    await (db.delete(db.aiConversations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await db.delete(db.aiMessages).go();
    await db.delete(db.aiConversations).go();
  }

  Future<void> addMessage({
    required int conversationId,
    required String role,
    required String message,
  }) async {
    await db.into(db.aiMessages).insert(
          AiMessagesCompanion.insert(
            conversationId: conversationId,
            role: role,
            message: message,
            createdAt: DateTime.now(),
          ),
        );
    await (db.update(db.aiConversations)
          ..where((t) => t.id.equals(conversationId)))
        .write(AiConversationsCompanion(updatedAt: Value(DateTime.now())));
  }
}
