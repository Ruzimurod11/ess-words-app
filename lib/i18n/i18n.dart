import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads the uz/en/ru translation JSON assets (shared verbatim with the web
/// app) and resolves dotted keys with `{{param}}` interpolation — the same
/// contract i18next used on the frontend. No pluralization is used by the
/// source strings, so a plain lookup + interpolation is sufficient.
class I18nStore {
  I18nStore._();
  static final I18nStore instance = I18nStore._();

  final Map<String, Map<String, dynamic>> _byLang = {};

  Future<void> load() async {
    for (final lang in const ['uz', 'en', 'ru']) {
      final raw = await rootBundle.loadString('assets/i18n/$lang.json');
      _byLang[lang] = json.decode(raw) as Map<String, dynamic>;
    }
  }

  String t(String lang, String key, [Map<String, Object?>? params]) {
    final resolved =
        _lookup(_byLang[lang], key) ?? _lookup(_byLang['uz'], key) ?? key;
    if (params == null || params.isEmpty) return resolved;
    var out = resolved;
    params.forEach((k, v) {
      out = out.replaceAll('{{$k}}', '${v ?? ''}');
    });
    return out;
  }

  String? _lookup(Map<String, dynamic>? root, String key) {
    if (root == null) return null;
    dynamic node = root;
    for (final part in key.split('.')) {
      if (node is Map && node.containsKey(part)) {
        node = node[part];
      } else {
        return null;
      }
    }
    return node is String ? node : null;
  }
}
