import 'package:ess_words/core/quiz_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowFireworks', () {
    test('fires on every kFireworksStreak-th consecutive correct answer', () {
      expect(shouldShowFireworks(kFireworksStreak), isTrue);
      expect(shouldShowFireworks(kFireworksStreak * 2), isTrue);
      expect(shouldShowFireworks(kFireworksStreak * 3), isTrue);
    });

    test('stays quiet between the milestones and with no streak', () {
      expect(shouldShowFireworks(0), isFalse);
      expect(shouldShowFireworks(kFireworksStreak - 1), isFalse);
      expect(shouldShowFireworks(kFireworksStreak + 1), isFalse);
    });
  });
}
