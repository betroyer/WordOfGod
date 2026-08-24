import 'package:drift/drift.dart';

class BibleBooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get abbrev => text()();
  IntColumn get testament => integer()();
  IntColumn get bookOrder => integer()();
}

class BibleChapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(BibleBooks, #id)();
  IntColumn get chapter => integer()();
  IntColumn get verseCount => integer()();
}

class BibleVerses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(BibleBooks, #id)();
  IntColumn get chapter => integer()();
  IntColumn get verse => integer()();
  TextColumn get content => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {bookId, chapter, verse},
      ];
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get verseId => integer().references(BibleVerses, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get verseId => integer().references(BibleVerses, #id)();
  DateTimeColumn get createdAt => dateTime()();
}

class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get verseId => integer().references(BibleVerses, #id)();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get verseId => integer().references(BibleVerses, #id)();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Reflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get read => text()();
  TextColumn get learned => text()();
  TextColumn get spoke => text()();
  TextColumn get apply => text()();
  TextColumn get pray => text()();
  IntColumn get verseId => integer().nullable().references(BibleVerses, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Prayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DevotionalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get reference => text()();
  TextColumn get title => text()();
  TextColumn get reflection => text()();
  TextColumn get application => text()();
  TextColumn get prayer => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ReadingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get status => text().withDefault(const Constant('idle'))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class ReadingPlanItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(ReadingPlans, #id)();
  IntColumn get dayNumber => integer()();
  IntColumn get bookId => integer().references(BibleBooks, #id)();
  IntColumn get chapter => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class ReadingProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(BibleBooks, #id)();
  IntColumn get chapter => integer()();
  DateTimeColumn get readAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {bookId, chapter},
      ];
}

class ReadingHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(BibleBooks, #id)();
  IntColumn get chapter => integer()();
  DateTimeColumn get startedAt => dateTime()();
}

class AiConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class AiMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(AiConversations, #id)();
  TextColumn get role => text()();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();
}
