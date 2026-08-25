import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Avatar sizing mirrors the web app: the picked photo is centre-cropped to a
/// square, scaled to 256x256 and sent as a data URL, because the backend keeps
/// the image as base64 text in the database rather than as a file.
const int kAvatarSize = 256;
const int kMaxSourceBytes = 5 * 1024 * 1024;

/// Encodes as JPEG (not WebP like the web build) — the pure-Dart `image`
/// package can decode WebP but not encode it, and the backend accepts
/// png/jpeg/webp alike.
String? avatarDataUrl(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized =
      img.copyResize(square, width: kAvatarSize, height: kAvatarSize);

  final jpeg = img.encodeJpg(resized, quality: 85);
  return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
}

// The header rebuilds often, and MemoryImage compares its bytes by identity —
// handing back the same Uint8List keeps Flutter from re-decoding (and the
// avatar from flickering) on every rebuild. Two entries, because the profile
// screen shows the saved avatar in the header and a freshly picked one in the
// form at the same time; a single slot would let them evict each other.
final _cache = <String, Uint8List>{};

/// Raw bytes behind a "data:image/...;base64,..." URL, or null if it is not
/// one we can read.
Uint8List? decodeAvatar(String? dataUrl) {
  if (dataUrl == null || !dataUrl.startsWith('data:')) return null;
  final hit = _cache[dataUrl];
  if (hit != null) return hit;
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return null;
  try {
    final bytes = base64Decode(dataUrl.substring(comma + 1));
    if (_cache.length >= 2) _cache.remove(_cache.keys.first);
    _cache[dataUrl] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}
