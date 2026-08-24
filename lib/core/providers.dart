import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/bible_seeder.dart';
import '../data/repositories/ai_repository.dart';
import '../data/repositories/bible_repository.dart';
import '../data/repositories/journal_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/study_repository.dart';
import '../services/ai_service.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final seederProvider = Provider<BibleSeeder>(
  (ref) => BibleSeeder(ref.watch(databaseProvider)),
);

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => BibleRepository(ref.watch(databaseProvider)),
);

final studyRepositoryProvider = Provider<StudyRepository>(
  (ref) => StudyRepository(
    ref.watch(databaseProvider),
    ref.watch(bibleRepositoryProvider),
  ),
);

final journalRepositoryProvider = Provider<JournalRepository>(
  (ref) => JournalRepository(ref.watch(databaseProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.watch(databaseProvider)),
);

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('settingsServiceProvider must be overridden');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

final networkServiceProvider = Provider<NetworkService>(
  (ref) => NetworkService(),
);

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final network = ref.watch(networkServiceProvider);
  yield await network.isOnline;
  yield* network.onStatusChange;
});

final aiServiceProvider = Provider<AiService>(
  (ref) => AiService(network: ref.watch(networkServiceProvider)),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsServiceProvider).load();

  Future<void> update(AppSettings next) async {
    state = next;
    await ref.read(settingsServiceProvider).save(next);
    await ref.read(notificationServiceProvider).sync(next);
  }

  Future<void> useGroqDefaults() async {
    await ref.read(settingsServiceProvider).applyGroqDefaults();
    state = ref.read(settingsServiceProvider).load();
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
