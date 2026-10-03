import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart' as api;
import '../../core/api_client.dart';
import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../components/topic_dialog.dart';
import '../components/unit_close_button.dart';
import '../components/unit_tabs.dart';
import '../components/word_form.dart';
import '../components/words_table.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/loader.dart';

class BookScreen extends ConsumerStatefulWidget {
  final int bookId;
  final int? initialUnitId;
  const BookScreen({super.key, required this.bookId, this.initialUnitId});

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  int? _activeUnitId;
  bool _creatingUnit = false;
  String? _unitError;

  @override
  void initState() {
    super.initState();
    _activeUnitId = widget.initialUnitId;
  }

  int? _resolveActive(BookWithUnits book) {
    if (book.units.isEmpty) return null;
    if (_activeUnitId != null &&
        book.units.any((u) => u.id == _activeUnitId)) {
      return _activeUnitId;
    }
    return book.units.first.id;
  }

  Future<void> _createUnit() async {
    setState(() {
      _creatingUnit = true;
      _unitError = null;
    });
    try {
      final unit = await api.createTopicUnit(widget.bookId);
      ref.invalidate(bookProvider(widget.bookId));
      ref.invalidate(booksProvider);
      if (mounted) setState(() => _activeUnitId = unit.id);
    } on ApiException catch (e) {
      if (mounted) setState(() => _unitError = e.message);
    } catch (_) {
      if (mounted) setState(() => _unitError = ref.trs('common.error'));
    } finally {
      if (mounted) setState(() => _creatingUnit = false);
    }
  }

  Future<void> _editTopic(BookWithUnits book) async {
    await showTopicDialog(
      context,
      topicId: book.id,
      title: book.title,
      description: book.description,
    );
  }

  Future<void> _deleteTopic(BookWithUnits book) async {
    final ok = await showConfirmDialog(
      context: context,
      title: ref.trs('topic.delete_title'),
      message: Text(ref.trs('topic.delete_confirm', {'title': book.title})),
      confirmLabel: ref.trs('common.delete'),
      cancelLabel: ref.trs('common.cancel'),
    );
    if (!ok || !mounted) return;
    try {
      await api.deleteTopic(book.id);
      ref.invalidate(booksProvider);
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ref.trs('common.error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final async = ref.watch(bookProvider(widget.bookId));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Loader()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: StateCard(
            error: true, child: Text('${ref.tr('common.error')}: $e')),
      ),
      data: (book) {
        final activeId = _resolveActive(book);
        UnitSummary? activeUnit;
        for (final u in book.units) {
          if (u.id == activeId) {
            activeUnit = u;
            break;
          }
        }
        final isAdmin = ref.watch(isAdminProvider);
        final isTopic = book.kind == BookKind.topic;
        final closed = activeUnit?.closed ?? false;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _BackLink(label: ref.tr('common.back_to_books')),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      if (book.description != null &&
                          book.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(book.description!,
                            style: TextStyle(fontSize: 13, color: c.mutedFg)),
                      ],
                      if (isAdmin && isTopic) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            GhostButton(
                              onPressed: () => _editTopic(book),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit, size: 16),
                                  const SizedBox(width: 6),
                                  Text(ref.tr('common.edit')),
                                ],
                              ),
                            ),
                            DangerButton(
                              onPressed: () => _deleteTopic(book),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delete, size: 16),
                                  const SizedBox(width: 6),
                                  Text(ref.tr('common.delete')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (book.units.isEmpty)
              StateCard(child: Text(ref.tr('book.no_units')))
            else ...[
              UnitTabs(
                units: book.units,
                activeUnitId: activeId,
                onSelect: (id) => setState(() => _activeUnitId = id),
              ),
              const SizedBox(height: 16),
              if (activeUnit != null && activeId != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(activeUnit.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(
                        ref.tr('book.word_count',
                            {'count': activeUnit.wordCount}),
                        style: TextStyle(fontSize: 13, color: c.mutedFg)),
                    if (closed) const ClosedBadge(),
                    if (isAdmin)
                      UnitCloseButton(unitId: activeId, closed: closed),
                    if (isAdmin && isTopic)
                      PrimaryButton(
                        onPressed: _creatingUnit ? null : _createUnit,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: 4),
                            Text(ref.tr(_creatingUnit
                                ? 'topic.creating_unit'
                                : 'topic.new_unit')),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_unitError != null) ...[
                  const SizedBox(height: 12),
                  StateCard(error: true, child: Text(_unitError!)),
                ],
                const SizedBox(height: 12),
                if (isAdmin && !closed) ...[
                  WordForm(key: ValueKey('form-$activeId'), unitId: activeId),
                  const SizedBox(height: 16),
                ],
                if (isAdmin && closed) ...[
                  StateCard(child: Text(ref.tr('book.unit_closed_hint'))),
                  const SizedBox(height: 16),
                ],
                WordsTable(key: ValueKey('table-$activeId'), unitId: activeId),
              ],
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _BackLink extends StatelessWidget {
  final String label;
  const _BackLink({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () => context.go('/'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 16, color: c.mutedFg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: c.mutedFg)),
        ],
      ),
    );
  }
}
