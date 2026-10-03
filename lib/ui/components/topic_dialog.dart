import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Create or edit a topic. Returns the saved book, or null if cancelled.
Future<BookWithUnits?> showTopicDialog(
  BuildContext context, {
  int? topicId,
  String title = '',
  String? description,
}) {
  return showDialog<BookWithUnits>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _TopicDialog(
      topicId: topicId,
      initialTitle: title,
      initialDescription: description ?? '',
    ),
  );
}

class _TopicDialog extends ConsumerStatefulWidget {
  final int? topicId;
  final String initialTitle;
  final String initialDescription;
  const _TopicDialog({
    required this.topicId,
    required this.initialTitle,
    required this.initialDescription,
  });

  @override
  ConsumerState<_TopicDialog> createState() => _TopicDialogState();
}

class _TopicDialogState extends ConsumerState<_TopicDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  late final TextEditingController _description =
      TextEditingController(text: widget.initialDescription);
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = ref.trs('topic.title_required'));
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    final description = _description.text.trim();
    try {
      final book = widget.topicId == null
          ? await api.createTopic(
              title: title,
              description: description.isEmpty ? null : description,
            )
          : await api.updateTopic(
              widget.topicId!,
              title: title,
              description: description.isEmpty ? null : description,
            );
      ref.invalidate(booksProvider);
      ref.invalidate(bookProvider(book.id));
      if (mounted) Navigator.of(context).pop(book);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = ref.trs('common.error'));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final editing = widget.topicId != null;
    final canSave = !_pending && _title.text.trim().isNotEmpty;
    return Dialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ref.tr(editing ? 'topic.edit_title' : 'topic.add_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(ref.tr('topic.name_label'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            AppTextField(
              controller: _title,
              autofocus: true,
              enabled: !_pending,
              hint: ref.tr('topic.name_placeholder'),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
                setState(() {});
              },
              onSubmitted: (_) {
                if (canSave) _save();
              },
            ),
            const SizedBox(height: 12),
            Text(ref.tr('topic.description_label'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            AppTextField(
              controller: _description,
              enabled: !_pending,
              hint: ref.tr('topic.description_placeholder'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(fontSize: 13, color: c.destructive)),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GhostButton(
                  onPressed: _pending ? null : () => Navigator.of(context).pop(),
                  child: Text(ref.tr('common.cancel')),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  onPressed: canSave ? _save : null,
                  child: Text(ref.tr(_pending ? 'topic.saving' : 'common.save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
