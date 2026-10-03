import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../theme.dart';

/// One player for the whole app: a word list materializes every row at once
/// (up to 100), and an AudioPlayer per row would mean that many native players
/// and event channels. Sharing one also makes a second tap stop the first
/// pronunciation instead of overlapping it.
final _player = AudioPlayer();

/// The media type of a data URL — "audio/mpeg" for
/// "data:audio/mpeg;base64,...". Null when there is none to read.
String? dataUrlMimeType(String url) {
  final comma = url.indexOf(',');
  if (!url.startsWith('data:') || comma < 0) return null;
  final semi = url.indexOf(';');
  final end = (semi >= 0 && semi < comma) ? semi : comma;
  final mime = url.substring(5, end);
  return mime.isEmpty ? null : mime;
}

/// Plays a word's pronunciation. Google TTS audio arrives as a
/// "data:audio/mpeg;base64,..." URL, which is decoded and played from memory;
/// anything else goes through the backend proxy (same as the web app).
class AudioButton extends StatelessWidget {
  final String url;
  final String tooltip;
  final double size;
  /// Quiz options use a tinted chip; the word list keeps a plain icon.
  final bool filled;
  /// White icon on a correct/incorrect option that is already colored.
  final bool onLight;
  const AudioButton({
    super.key,
    required this.url,
    required this.tooltip,
    this.size = 18,
    this.filled = false,
    this.onLight = false,
  });

  Future<void> _play() async {
    try {
      await _player.stop();
      await _player.play(_source(url));
    } catch (e) {
      debugPrint('Audio playback failed: $e');
    }
  }

  Source _source(String url) {
    if (!url.startsWith('data:')) {
      return UrlSource('$apiRoot/audio/proxy?url=${Uri.encodeComponent(url)}');
    }
    // Pass the MIME type through: on iOS/macOS audioplayers spills the bytes
    // to an extensionless temp file, and without a type AVFoundation cannot
    // tell what it is holding.
    final comma = url.indexOf(',');
    return BytesSource(
      base64Decode(url.substring(comma + 1)),
      mimeType: dataUrlMimeType(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = onLight ? Colors.white : c.primary;
    final bg = onLight
        ? Colors.white.withValues(alpha: 0.20)
        : c.primary.withValues(alpha: 0.10);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? bg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _play,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.volume_up, size: size, color: fg),
          ),
        ),
      ),
    );
  }
}
