import 'package:go_router/go_router.dart';

import '../../features/ai_assistant/ai_assistant_screen.dart';
import '../../features/ai_assistant/ai_history_screen.dart';
import '../../features/bible/bible_books_screen.dart';
import '../../features/bible/bible_reader_screen.dart';
import '../../features/bookmarks/bookmarks_screen.dart';
import '../../features/devotional/devotional_editor_screen.dart';
import '../../features/devotional/devotionals_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/highlights/highlights_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/journal/journal_hub_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/prayer/prayer_editor_screen.dart';
import '../../features/prayer/prayers_screen.dart';
import '../../features/reading_plans/plan_detail_screen.dart';
import '../../features/reading_plans/plans_screen.dart';
import '../../features/reflections/reflection_editor_screen.dart';
import '../../features/reflections/reflections_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/study/study_hub_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (c, s) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'stats',
                  builder: (c, s) => const StatisticsScreen(),
                ),
                GoRoute(
                  path: 'plans',
                  builder: (c, s) => const PlansScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (c, s) => PlanDetailScreen(
                        planId: int.parse(s.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bible',
              builder: (c, s) => const BibleBooksScreen(),
              routes: [
                GoRoute(
                  path: ':bookId/:chapter',
                  builder: (c, s) => BibleReaderScreen(
                    bookId: int.parse(s.pathParameters['bookId']!),
                    chapter: int.parse(s.pathParameters['chapter']!),
                    highlightVerse: int.tryParse(
                      s.uri.queryParameters['verse'] ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/study',
              builder: (c, s) => const StudyHubScreen(),
              routes: [
                GoRoute(path: 'search', builder: (c, s) => const SearchScreen()),
                GoRoute(
                  path: 'bookmarks',
                  builder: (c, s) => const BookmarksScreen(),
                ),
                GoRoute(
                  path: 'favorites',
                  builder: (c, s) => const FavoritesScreen(),
                ),
                GoRoute(
                  path: 'highlights',
                  builder: (c, s) => const HighlightsScreen(),
                ),
                GoRoute(
                  path: 'notes',
                  builder: (c, s) => const NotesScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (c, s) => const JournalHubScreen(),
              routes: [
                GoRoute(
                  path: 'reflections',
                  builder: (c, s) => const ReflectionsScreen(),
                ),
                GoRoute(
                  path: 'prayers',
                  builder: (c, s) => const PrayersScreen(),
                ),
                GoRoute(
                  path: 'devotionals',
                  builder: (c, s) => const DevotionalsScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/ai',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>?;
        return AiAssistantScreen(
          verseId: extra?['verseId'] as int?,
          prompt: extra?['prompt'] as String?,
          conversationId: extra?['conversationId'] as int?,
        );
      },
    ),
    GoRoute(path: '/ai/history', builder: (c, s) => const AiHistoryScreen()),
    GoRoute(
      path: '/note/edit',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return NoteEditorScreen(
          verseId: extra['verseId'] as int,
          noteId: extra['noteId'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/reflection/edit',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return ReflectionEditorScreen(
          reflectionId: extra['id'] as int?,
          verseId: extra['verseId'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/prayer/edit',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return PrayerEditorScreen(prayerId: extra['id'] as int?);
      },
    ),
    GoRoute(
      path: '/devotional/edit',
      builder: (c, s) {
        final extra = s.extra as Map<String, dynamic>? ?? {};
        return DevotionalEditorScreen(entryId: extra['id'] as int?);
      },
    ),
  ],
);
