import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/app_shell.dart';
import 'ui/screens/book_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/test/test_screen.dart';
import 'ui/screens/vocabulary_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/test',
            pageBuilder: (c, s) => const NoTransitionPage(child: TestScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (c, s) => NoTransitionPage(
              child: SearchScreen(query: s.uri.queryParameters['q'] ?? ''),
            ),
          ),
          GoRoute(
            path: '/vocabulary',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: VocabularyScreen()),
          ),
          GoRoute(
            path: '/books/:id',
            pageBuilder: (c, s) {
              final id = int.tryParse(s.pathParameters['id'] ?? '') ?? 0;
              final unit = int.tryParse(s.uri.queryParameters['unit'] ?? '');
              return NoTransitionPage(
                child: BookScreen(bookId: id, initialUnitId: unit),
              );
            },
          ),
        ],
      ),
    ],
  );
});
