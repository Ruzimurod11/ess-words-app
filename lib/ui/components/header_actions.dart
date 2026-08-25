import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/avatar_view.dart';
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

enum _AdminMenu { profile, logout }

/// Lock icon while signed out; once signed in it becomes the profile avatar,
/// which opens a Profile/Logout menu. Merging the two keeps the AppBar from
/// growing an extra action on narrow phones.
class AdminButton extends ConsumerWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return IconBtn(
        icon: Icons.lock_outline,
        tooltip: ref.tr('admin.login'),
        onPressed: () => _showLoginDialog(context, ref),
      );
    }

    final c = context.c;
    final avatar = ref.watch(profileProvider).valueOrNull?.avatar;
    return PopupMenuButton<_AdminMenu>(
      tooltip: ref.tr('profile.title'),
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      onSelected: (v) => switch (v) {
        _AdminMenu.profile => context.go('/profile'),
        _AdminMenu.logout => ref.read(authProvider.notifier).clear(),
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: _AdminMenu.profile,
          child: Row(children: [
            Icon(Icons.person_outline, size: 18, color: c.mutedFg),
            const SizedBox(width: 10),
            Text(ref.trs('profile.title')),
          ]),
        ),
        PopupMenuItem(
          value: _AdminMenu.logout,
          child: Row(children: [
            Icon(Icons.lock_open_outlined, size: 18, color: c.mutedFg),
            const SizedBox(width: 10),
            Text(ref.trs('admin.logout')),
          ]),
        ),
      ],
      child: AvatarView(dataUrl: avatar, size: 40, radius: 12),
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

/// The three admin maintenance backfills, collapsed into one overflow menu —
/// as separate icons they no longer fit next to the language/theme/profile
/// actions on a narrow phone AppBar.
enum _Tool { transcription, partOfSpeech, googleTts }

class AdminToolsButton extends ConsumerStatefulWidget {
  const AdminToolsButton({super.key});
  @override
  ConsumerState<AdminToolsButton> createState() => _AdminToolsButtonState();
}

class _AdminToolsButtonState extends ConsumerState<AdminToolsButton> {
  // Google TTS is capped per call by the backend, so it runs in batches.
  static const _ttsBatchSize = 50;

  _Tool? _running;

  Future<void> _run(_Tool tool) async {
    setState(() => _running = tool);
    try {
      final (res, messageKey) = switch (tool) {
        _Tool.transcription => (
            await api.backfillTranscriptions(),
            'transcription.success',
          ),
        _Tool.partOfSpeech => (
            await api.backfillPartsOfSpeech(),
            'part_of_speech.success',
          ),
        _Tool.googleTts => (await _runTts(), 'google_tts.success'),
      };
      invalidateWords(ref, 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.trs(messageKey, {
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
      if (mounted) setState(() => _running = null);
    }
  }

  /// Loops until nothing is left — or until a batch produces nothing, which
  /// means TTS is failing and looping further would never terminate.
  Future<api.BackfillResult> _runTts() async {
    var updated = 0;
    var remaining = 0;
    while (true) {
      final res = await api.backfillAudioWithGoogleTts(_ttsBatchSize);
      updated += res.updated;
      remaining = res.remaining;
      if (res.remaining == 0 || res.updated == 0) break;
    }
    return api.BackfillResult(updated, remaining);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminProvider)) return const SizedBox.shrink();
    final c = context.c;
    final busy = _running != null;
    return PopupMenuButton<_Tool>(
      enabled: !busy,
      tooltip: ref.tr('admin_tools.label'),
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      onSelected: _run,
      itemBuilder: (ctx) => [
        _item(_Tool.transcription, Icons.auto_awesome_outlined,
            ref.trs('transcription.button')),
        _item(_Tool.partOfSpeech, Icons.sell_outlined,
            ref.trs('part_of_speech.button')),
        _item(_Tool.googleTts, Icons.graphic_eq,
            ref.trs('google_tts.button')),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Icon(busy ? Icons.hourglass_top : Icons.build_outlined,
            size: 20, color: c.mutedFg),
      ),
    );
  }

  PopupMenuItem<_Tool> _item(_Tool tool, IconData icon, String label) {
    final c = context.c;
    return PopupMenuItem<_Tool>(
      value: tool,
      child: Row(children: [
        Icon(icon, size: 18, color: c.mutedFg),
        const SizedBox(width: 10),
        Text(label),
      ]),
    );
  }
}
