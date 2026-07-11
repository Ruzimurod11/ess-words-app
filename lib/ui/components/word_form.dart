import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Add-a-word form (WordForm.tsx). In unit mode pass [unitId]; alternatively
/// pass [submitWord] (e.g. vocabulary auto-tagging) and [onAdded].
class WordForm extends ConsumerStatefulWidget {
  final int? unitId;
  final Future<void> Function(Map<String, dynamic> data)? submitWord;
  final VoidCallback? onAdded;
  const WordForm({super.key, this.unitId, this.submitWord, this.onAdded});

  @override
  ConsumerState<WordForm> createState() => _WordFormState();
}

class _WordFormState extends ConsumerState<WordForm> {
  final _english = TextEditingController();
  final _translation = TextEditingController();
  final _englishFocus = FocusNode();
  bool _pending = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _english.dispose();
    _translation.dispose();
    _englishFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final en = _english.text.trim();
    final tr = _translation.text.trim();
    if (en.isEmpty || tr.isEmpty) {
      setState(() => _error = ref.trs('word_form.both_required'));
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final payload = {'english': en, 'translation': tr};
      if (widget.submitWord != null) {
        await widget.submitWord!(payload);
      } else {
        await api.createUnitWord(widget.unitId!, payload);
      }
      if (widget.unitId != null) invalidateWords(ref, widget.unitId!);
      widget.onAdded?.call();
      if (!mounted) return;
      _english.clear();
      _translation.clear();
      setState(() => _success = true);
      _englishFocus.requestFocus();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _success = false);
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = ref.trs('common.error'));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, size: 16, color: c.primary),
              ),
              const SizedBox(width: 8),
              Text(ref.tr('word_form.title'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_success)
                Row(
                  children: [
                    Icon(Icons.check, size: 16, color: c.success),
                    const SizedBox(width: 4),
                    Text(ref.tr('word_form.success'),
                        style: TextStyle(
                            fontSize: 13,
                            color: c.success,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _label(ref.tr('word_form.english_label')),
          const SizedBox(height: 4),
          AppTextField(
            controller: _english,
            enabled: !_pending,
            hint: ref.tr('word_form.english_placeholder'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          _label(ref.tr('word_form.translation_label')),
          const SizedBox(height: 4),
          AppTextField(
            controller: _translation,
            enabled: !_pending,
            hint: ref.tr('word_form.translation_placeholder'),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              onPressed: _pending ? null : _submit,
              child: Text(_pending
                  ? ref.tr('word_form.submitting')
                  : ref.tr('word_form.submit')),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            StateCard(error: true, child: Text(_error!)),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
}
