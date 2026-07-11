// Smoke test: the app builds and mounts without throwing.
// booksProvider is overridden so no real HTTP fires during the test.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ess_words/i18n/i18n.dart';
import 'package:ess_words/models/book.dart';
import 'package:ess_words/state/app_state.dart';
import 'package:ess_words/state/data.dart';
import 'package:ess_words/main.dart';

void main() {
  testWidgets('App builds and mounts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await I18nStore.instance.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booksProvider.overrideWith((ref) async => <Book>[]),
        ],
        child: const EssWordsApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(EssWordsApp), findsOneWidget);
  });
}
