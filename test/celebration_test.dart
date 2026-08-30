// Smoke test: the celebration overlay animates and paints without throwing —
// it emits, advances and disposes hundreds of particles plus rasterized emoji.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ess_words/ui/screens/test/celebration.dart';

void main() {
  testWidgets('Celebration runs its whole sequence without throwing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Stack(children: [Positioned.fill(child: Celebration())])),
    );

    // butun ketma-ketlik: markaziy portlash, yon to'plar, emoji, oqim
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);

    // effekt QuizGame tomonidan olib tashlanishi — dispose ham toza bo'lsin
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
