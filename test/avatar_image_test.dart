import 'dart:convert';
import 'dart:typed_data';

import 'package:ess_words/core/avatar_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _png(int width, int height) =>
    Uint8List.fromList(img.encodePng(img.Image(width: width, height: height)));

void main() {
  group('avatarDataUrl', () {
    test('centre-crops a wide image to a square 256x256 JPEG', () {
      final url = avatarDataUrl(_png(800, 400));
      expect(url, isNotNull);
      expect(url, startsWith('data:image/jpeg;base64,'));

      final decoded = img.decodeJpg(decodeAvatar(url)!)!;
      expect(decoded.width, kAvatarSize);
      expect(decoded.height, kAvatarSize);
    });

    test('returns null for bytes that are not an image', () {
      expect(avatarDataUrl(Uint8List.fromList(utf8.encode('not an image'))),
          isNull);
    });

    test('stays well under the backend 700KB avatar cap', () {
      final url = avatarDataUrl(_png(2000, 2000))!;
      expect(url.length, lessThan(700000));
    });
  });

  group('decodeAvatar', () {
    test('returns null for a non-data URL', () {
      expect(decodeAvatar('https://example.com/a.png'), isNull);
      expect(decodeAvatar(null), isNull);
    });

    test('returns the identical list for a repeated URL so the image cache '
        'is not invalidated on every rebuild', () {
      final url = avatarDataUrl(_png(300, 300))!;
      expect(identical(decodeAvatar(url), decodeAvatar(url)), isTrue);
    });
  });
}
