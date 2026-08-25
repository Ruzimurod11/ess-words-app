// Smoke test: the app builds and mounts without throwing.
// booksProvider is overridden so no real HTTP fires during the test.
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ess_words/i18n/i18n.dart';
import 'package:ess_words/models/book.dart';
import 'package:ess_words/state/app_state.dart';
import 'package:ess_words/state/data.dart';
import 'package:ess_words/main.dart';

Book _book({required int id, required String title, required BookKind kind}) =>
    Book(
      id: id,
      order: id,
      title: title,
      description: null,
      kind: kind,
      unitCount: 67,
      wordCount: 2665,
    );

Future<void> _mount(WidgetTester tester, List<Book> books) async {
  // The home ListView builds lazily, so the surface has to be tall enough for
  // the sections below the books grid to exist at all.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        booksProvider.overrideWith((ref) => books),
      ],
      child: const EssWordsApp(),
    ),
  );
  // First frames go to the router/shell before HomeScreen's list is laid out.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // Loading prefs and the i18n assets is real async I/O, so it has to happen
  // outside the fake-async zone testWidgets runs its body in.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await I18nStore.instance.load();
  });

  testWidgets('App builds and mounts', (WidgetTester tester) async {
    await _mount(tester, <Book>[]);
    expect(find.byType(EssWordsApp), findsOneWidget);
  });

  testWidgets('the passages book gets its own home section',
      (WidgetTester tester) async {
    await _mount(tester, [
      _book(id: 19, title: 'INTERMEDIATE PASSEGES', kind: BookKind.passages),
    ]);

    // Section heading + card title both read the same key.
    expect(find.text('INTERMEDIATE PASSEGES'), findsNWidgets(2));
    expect(
      find.text("ELS Vocabulary — 67 ta matn, har biri alohida bo'lim."),
      findsOneWidget,
    );
  });

  testWidgets('no passages book means no passages section',
      (WidgetTester tester) async {
    await _mount(tester, [
      _book(id: 1, title: 'Book 1', kind: BookKind.essential),
    ]);

    expect(find.text('INTERMEDIATE PASSEGES'), findsNothing);
  });
}
