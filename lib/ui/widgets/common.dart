import 'package:flutter/material.dart';

import '../theme.dart';

/// Rounded, bordered card surface (ui.tsx `card`).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.primaryFg,
        disabledBackgroundColor: c.primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: child,
    );
  }
}

class GhostButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const GhostButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: c.card,
        foregroundColor: c.foreground,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      child: child,
    );
  }
}

class DangerButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const DangerButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.destructive,
        foregroundColor: c.destructiveFg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: child,
    );
  }
}

/// Square bordered icon button (ui.tsx `btn.icon`).
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  const IconBtn({super.key, required this.icon, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: 20, color: c.mutedFg),
          ),
        ),
      ),
    );
  }
}

/// Empty / error state card (ui.tsx StateCard).
class StateCard extends StatelessWidget {
  final Widget child;
  final bool error;
  const StateCard({super.key, required this.child, this.error = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.destructive.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.destructive.withValues(alpha: 0.3)),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: c.destructive, fontSize: 14),
          child: child,
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: TextStyle(color: c.mutedFg, fontSize: 14),
          child: child,
        ),
      ),
    );
  }
}

/// Small rounded pill/badge.
class Pill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  const Pill(this.text, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? c.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg ?? c.primary,
        ),
      ),
    );
  }
}

/// A styled text field matching the web `input` token.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final TextAlign textAlign;
  final Color? ringColor;
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.textAlign = TextAlign.start,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      enabled: enabled,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textAlign: textAlign,
      style: TextStyle(color: c.foreground, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: c.card,
        hintText: hint,
        hintStyle: TextStyle(color: c.mutedFg),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _b(c, ringColor ?? c.input),
        enabledBorder: _b(c, ringColor ?? c.input),
        focusedBorder: _b(c, ringColor ?? c.primary, width: 2),
        disabledBorder: _b(c, c.input),
      ),
    );
  }

  OutlineInputBorder _b(AppColors c, Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
