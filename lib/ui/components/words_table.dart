import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../models/word.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/loader.dart';

class WordsTable extends ConsumerStatefulWidget {
  final int unitId;
  const WordsTable({super.key, required this.unitId});

  @override
  ConsumerState<WordsTable> createState() => _WordsTableState();
}

class _WordsTableState extends ConsumerState<WordsTable> {
  int _page = 1;
  int _pageSize = 20;
  int? _editingId;
  final _english = TextEditingController();
  final _translation = TextEditingController();
  final _transcription = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _english.dispose();
    _translation.dispose();
    _transcription.dispose();
    super.dispose();
  }

  void _startEdit(Word w) {
    _english.text = w.english;
    _translation.text = w.translation;
    _transcription.text = w.transcription ?? '';
    setState(() => _editingId = w.id);
  }

  Future<void> _saveEdit() async {
    final id = _editingId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await api.updateWord(id, {
        'english': _english.text.trim(),
        'translation': _translation.text.trim(),
        'transcription': _transcription.text.trim().isEmpty
            ? null
            : _transcription.text.trim(),
      });
      setState(() => _editingId = null);
      invalidateWords(ref, widget.unitId);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Word w) async {
    final ok = await showConfirmDialog(
      context: context,
      title: ref.trs('words_table.delete_title'),
      message: Text.rich(TextSpan(children: [
        TextSpan(text: ref.trs('words_table.delete_confirm_prefix')),
        TextSpan(
            text: ' "${w.english}" ',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: context.c.foreground)),
        TextSpan(text: ref.trs('words_table.delete_confirm_suffix')),
      ])),
      confirmLabel: ref.trs('words_table.delete_button'),
      cancelLabel: ref.trs('common.cancel'),
    );
    if (!ok) return;
    try {
      await api.deleteWord(w.id);
      invalidateWords(ref, widget.unitId);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  // newIndex is already adjusted for the removal at oldIndex by
  // ReorderableListView's onReorderItem callback.
  Future<void> _reorder(List<Word> items, int oldIndex, int newIndex) async {
    final ids = items.map((w) => w.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    try {
      await api.reorderUnitWords(widget.unitId, ids);
      invalidateWords(ref, widget.unitId);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final async = ref.watch(unitWordsProvider(
        (unitId: widget.unitId, page: _page, pageSize: _pageSize)));
    final c = context.c;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${ref.tr('words_table.total_in_unit')} ',
                    style: TextStyle(color: c.mutedFg, fontSize: 13)),
                TextSpan(
                    text: '${async.valueOrNull?.total ?? 0} ',
                    style: TextStyle(
                        color: c.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                TextSpan(
                    text: ref.tr('words_table.word_unit'),
                    style: TextStyle(color: c.mutedFg, fontSize: 13)),
              ])),
            ),
            _PageSizeSelect(
              value: _pageSize,
              perPageLabel: ref.tr('common.per_page'),
              onChanged: (s) => setState(() {
                _pageSize = s;
                _page = 1;
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: async.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24), child: Loader(bare: true)),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                  child: Text('$e', style: TextStyle(color: c.destructive))),
            ),
            data: (data) {
              final items = data.items;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(ref.tr('words_table.empty'),
                        style: TextStyle(color: c.mutedFg)),
                  ),
                );
              }
              if (isAdmin) {
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorderItem: (o, n) => _reorder(items, o, n),
                  itemBuilder: (context, i) => _row(items[i], i, true),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: c.border),
                itemBuilder: (context, i) => _row(items[i], i, false),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _Pagination(
          page: _page,
          totalPages: async.valueOrNull?.totalPages ?? 1,
          busy: async.isLoading,
          onPrev: () => setState(() => _page = (_page - 1).clamp(1, 1 << 30)),
          onNext: () => setState(() {
            final tp = async.valueOrNull?.totalPages ?? 1;
            _page = (_page + 1).clamp(1, tp);
          }),
        ),
      ],
    );
  }

  Widget _row(Word w, int index, bool isAdmin) {
    final c = context.c;
    final editing = _editingId == w.id;
    return Container(
      key: ValueKey(w.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.6))),
      ),
      child: editing ? _editRow(w) : _viewRow(w, index, isAdmin),
    );
  }

  Widget _viewRow(Word w, int index, bool isAdmin) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isAdmin)
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.drag_indicator, size: 18, color: c.mutedFg),
            ),
          ),
        SizedBox(
          width: 22,
          child: Text('${w.order}',
              style: TextStyle(color: c.mutedFg, fontSize: 13)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(w.english,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w500)),
                  ),
                  if (w.transcription != null &&
                      w.transcription!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('[${w.transcription}]',
                          style: TextStyle(fontSize: 15, color: c.mutedFg)),
                    ),
                  ],
                ],
              ),
              Text(w.translation, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        if (isAdmin) ...[
          _iconAction(Icons.edit_outlined, c.primary, () => _startEdit(w)),
          _iconAction(
              Icons.delete_outline, c.destructive, () => _delete(w)),
        ],
      ],
    );
  }

  Widget _editRow(Word w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(controller: _english, hint: 'english'),
        const SizedBox(height: 6),
        AppTextField(controller: _transcription, hint: 'transcription'),
        const SizedBox(height: 6),
        AppTextField(controller: _translation, hint: 'translation'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: _saving ? null : _saveEdit,
              style: FilledButton.styleFrom(
                backgroundColor: context.c.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(ref.trs('common.save')),
            ),
            const SizedBox(width: 8),
            GhostButton(
              onPressed: () => setState(() => _editingId = null),
              child: Text(ref.trs('common.cancel')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PageSizeSelect extends StatelessWidget {
  final int value;
  final String perPageLabel;
  final ValueChanged<int> onChanged;
  const _PageSizeSelect({
    required this.value,
    required this.perPageLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopupMenuButton<int>(
      initialValue: value,
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border),
      ),
      onSelected: onChanged,
      itemBuilder: (ctx) => [5, 10, 20, 50, 100]
          .map((s) => PopupMenuItem(value: s, child: Text('$s $perPageLabel')))
          .toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value $perPageLabel',
                style: const TextStyle(fontSize: 14)),
            Icon(Icons.keyboard_arrow_down, size: 16, color: c.mutedFg),
          ],
        ),
      ),
    );
  }
}

class _Pagination extends ConsumerWidget {
  final int page;
  final int totalPages;
  final bool busy;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.busy,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${ref.tr('common.page')} $page ${ref.tr('common.of')} $totalPages',
            style: TextStyle(fontSize: 13, color: c.mutedFg)),
        Row(
          children: [
            GhostButton(
              onPressed: (page <= 1 || busy) ? null : onPrev,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chevron_left, size: 16),
                Text(ref.tr('common.previous')),
              ]),
            ),
            const SizedBox(width: 8),
            GhostButton(
              onPressed: (page >= totalPages || busy) ? null : onNext,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(ref.tr('common.next')),
                const Icon(Icons.chevron_right, size: 16),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}
