import 'package:flutter/material.dart';

/// Design tokens ported from the web app's Tailwind theme (index.css oklch
/// values converted to sRGB). Exposed as a [ThemeExtension] so widgets read
/// them via `context.c`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color foreground;
  final Color card;
  final Color primary;
  final Color primaryFg;
  final Color secondary;
  final Color secondaryFg;
  final Color muted;
  final Color mutedFg;
  final Color accent;
  final Color destructive;
  final Color destructiveFg;
  final Color border;
  final Color input;
  final Color success;
  final Color warning;

  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.primary,
    required this.primaryFg,
    required this.secondary,
    required this.secondaryFg,
    required this.muted,
    required this.mutedFg,
    required this.accent,
    required this.destructive,
    required this.destructiveFg,
    required this.border,
    required this.input,
    required this.success,
    required this.warning,
  });

  static const light = AppColors(
    background: Color(0xFFF6F7FD),
    foreground: Color(0xFF161726),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF615FFF),
    primaryFg: Color(0xFFFBFAFF),
    secondary: Color(0xFFE8EAF9),
    secondaryFg: Color(0xFF373896),
    muted: Color(0xFFEEF0F7),
    mutedFg: Color(0xFF66677A),
    accent: Color(0xFF8E51FF),
    destructive: Color(0xFFE7000B),
    destructiveFg: Color(0xFFFFFFFF),
    border: Color(0xFFDCDDE8),
    input: Color(0xFFDCDDE8),
    success: Color(0xFF18A349),
    warning: Color(0xFFF49F1E),
  );

  static const dark = AppColors(
    background: Color(0xFF0B0B15),
    foreground: Color(0xFFE6E7EF),
    card: Color(0xFF151622),
    primary: Color(0xFF7D86FF),
    primaryFg: Color(0xFFFBFAFF),
    secondary: Color(0xFF242641),
    secondaryFg: Color(0xFFC4CBF5),
    muted: Color(0xFF22232E),
    mutedFg: Color(0xFF9697A5),
    accent: Color(0xFFA784FF),
    destructive: Color(0xFFEF4444),
    destructiveFg: Color(0xFFFFFFFF),
    border: Color(0xFF2E2F3F),
    input: Color(0xFF2E2F3F),
    success: Color(0xFF22C560),
    warning: Color(0xFFF0B100),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}

/// The six card gradients cycled by book order (from ui.tsx BOOK_GRADIENTS).
const List<List<Color>> kBookGradients = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo -> violet
  [Color(0xFF8B5CF6), Color(0xFFD946EF)], // violet -> fuchsia
  [Color(0xFF3B82F6), Color(0xFF6366F1)], // blue -> indigo
  [Color(0xFFD946EF), Color(0xFFEC4899)], // fuchsia -> pink
  [Color(0xFF0EA5E9), Color(0xFF3B82F6)], // sky -> blue
  [Color(0xFFA855F7), Color(0xFF4F46E5)], // purple -> indigo
];

List<Color> bookGradient(int i) => kBookGradients[i.abs() % kBookGradients.length];

/// Primary brand gradient (indigo -> violet), used across headers and CTAs.
const kBrandGradient = [Color(0xFF6366F1), Color(0xFF7C3AED)];

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: c.background,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryFg,
      surface: c.card,
      onSurface: c.foreground,
      error: c.destructive,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: c.foreground,
      displayColor: c.foreground,
    ),
    extensions: [c],
  );
}
