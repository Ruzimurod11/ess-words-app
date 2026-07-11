import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    final isDark = mode == ThemeMode.dark;
    return IconBtn(
      icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      tooltip: isDark ? ref.tr('theme.light_title') : ref.tr('theme.dark_title'),
      onPressed: () => ref.read(themeProvider.notifier).toggle(),
    );
  }
}

const _flags = {'uz': '🇺🇿', 'en': '🇺🇸', 'ru': '🇷🇺'};
const _labels = {'uz': "O'zbekcha", 'en': 'English', 'ru': 'Русский'};

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final c = context.c;
    return PopupMenuButton<String>(
      tooltip: ref.tr('lang.label'),
      onSelected: (v) => ref.read(localeProvider.notifier).set(v),
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      itemBuilder: (ctx) => supportedLangs.map((lang) {
        return PopupMenuItem<String>(
          value: lang,
          child: Row(
            children: [
              Text(_flags[lang]!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(_labels[lang]!,
                  style: TextStyle(
                    color: lang == current ? c.primary : c.foreground,
                    fontWeight:
                        lang == current ? FontWeight.w600 : FontWeight.normal,
                  )),
              if (lang == current) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: c.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_flags[current]!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(current.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.mutedFg)),
            Icon(Icons.keyboard_arrow_down, size: 16, color: c.mutedFg),
          ],
        ),
      ),
    );
  }
}

class AdminButton extends ConsumerWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (isAdmin) {
      return IconBtn(
        icon: Icons.lock_open_outlined,
        tooltip: ref.tr('admin.logout'),
        onPressed: () => ref.read(authProvider.notifier).clear(),
      );
    }
    return IconBtn(
      icon: Icons.lock_outline,
      tooltip: ref.tr('admin.login'),
      onPressed: () => _showLoginDialog(context, ref),
    );
  }
}

Future<void> _showLoginDialog(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => const _AdminLoginDialog(),
  );
}

class _AdminLoginDialog extends ConsumerStatefulWidget {
  const _AdminLoginDialog();
  @override
  ConsumerState<_AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends ConsumerState<_AdminLoginDialog> {
  final _controller = TextEditingController();
  bool _show = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _controller.text.trim();
    if (pw.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await api.login(pw);
      ref.read(authProvider.notifier).setToken(token);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = ref.trs('common.error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(ref.tr('admin.title'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            AppTextField(
              controller: _controller,
              autofocus: true,
              obscure: !_show,
              enabled: !_loading,
              hint: ref.tr('admin.password_placeholder'),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              suffix: IconButton(
                icon: Icon(_show ? Icons.visibility_off : Icons.visibility,
                    size: 18, color: c.mutedFg),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              StateCard(error: true, child: Text(_error!)),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GhostButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ref.tr('common.cancel')),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading
                      ? ref.tr('admin.submitting')
                      : ref.tr('admin.submit')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin-only transcription backfill action (shows a snackbar with the result).
class TranscriptionBackfillButton extends ConsumerStatefulWidget {
  const TranscriptionBackfillButton({super.key});
  @override
  ConsumerState<TranscriptionBackfillButton> createState() =>
      _TranscriptionBackfillButtonState();
}

class _TranscriptionBackfillButtonState
    extends ConsumerState<TranscriptionBackfillButton> {
  bool _pending = false;

  Future<void> _run() async {
    setState(() => _pending = true);
    try {
      final res = await api.backfillTranscriptions();
      invalidateWords(ref, 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.trs('transcription.success', {
            'updated': res.updated,
            'remaining': res.remaining,
          })),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminProvider)) return const SizedBox.shrink();
    return IconBtn(
      icon: _pending ? Icons.hourglass_top : Icons.auto_awesome_outlined,
      tooltip: ref.tr('transcription.button'),
      onPressed: _pending ? null : _run,
    );
  }
}
