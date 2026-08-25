import 'package:ess_words/ui/widgets/audio_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dataUrlMimeType', () {
    test('reads the type out of a base64 data URL', () {
      expect(dataUrlMimeType('data:audio/mpeg;base64,AAAA'), 'audio/mpeg');
    });

    test('reads the type when there are no parameters', () {
      expect(dataUrlMimeType('data:audio/mpeg,AAAA'), 'audio/mpeg');
    });

    test('returns null for a plain URL or a typeless data URL', () {
      expect(dataUrlMimeType('https://example.com/a.mp3'), isNull);
      expect(dataUrlMimeType('data:;base64,AAAA'), isNull);
      expect(dataUrlMimeType('data:audio/mpeg'), isNull);
    });
  });
}
