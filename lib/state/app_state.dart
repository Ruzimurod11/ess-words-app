import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/session.dart';
import '../i18n/i18n.dart';

/// Set once in main() before runApp.
late SharedPreferences prefs;

const _kLang = 'lang';
const _kTheme = 'theme';
const _kToken = 'admin_token';
const supportedLangs = ['uz', 'en', 'ru'];
const defaultLang = 'uz';

// ---------------- locale ----------------
class LocaleController extends StateNotifier<String> {
  LocaleController() : super(_initial()) {
    Session.instance.language = state;
  }

  static String _initial() {
    final stored = prefs.getString(_kLang);
    return (stored != null && supportedLangs.contains(stored))
        ? stored
        : defaultLang;
  }

  void set(String lang) {
    if (!supportedLangs.contains(lang)) return;
    state = lang;
    Session.instance.language = lang;
    prefs.setString(_kLang, lang);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleController, String>((ref) => LocaleController());

// ---------------- theme ----------------
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(_initial());

  static ThemeMode _initial() =>
      prefs.getString(_kTheme) == 'dark' ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    prefs.setString(_kTheme, state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) => ThemeController());

// ---------------- auth ----------------
class AuthController extends StateNotifier<String?> {
  AuthController() : super(prefs.getString(_kToken)) {
    Session.instance.token = state;
    Session.instance.onUnauthorized.add(_onUnauthorized);
  }

  bool get isAdmin => state != null;

  void setToken(String token) {
    state = token;
    Session.instance.token = token;
    prefs.setString(_kToken, token);
  }

  void clear() {
    state = null;
    Session.instance.token = null;
    prefs.remove(_kToken);
  }

  void _onUnauthorized() {
    if (state != null) clear();
  }
}

final authProvider =
    StateNotifierProvider<AuthController, String?>((ref) => AuthController());

final isAdminProvider = Provider<bool>((ref) => ref.watch(authProvider) != null);

// ---------------- translation helper ----------------
extension Tr on WidgetRef {
  /// Reactive translate — use during build(); rebuilds the caller when the
  /// language changes. Must NOT be called from event callbacks (watch outside
  /// build throws); use [trs] there.
  String tr(String key, [Map<String, Object?>? params]) =>
      I18nStore.instance.t(watch(localeProvider), key, params);

  /// Non-reactive translate — safe inside event callbacks / async code.
  String trs(String key, [Map<String, Object?>? params]) =>
      I18nStore.instance.t(read(localeProvider), key, params);
}
