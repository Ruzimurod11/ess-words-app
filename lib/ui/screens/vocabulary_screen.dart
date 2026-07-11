import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart' as api;
import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../components/unit_tabs.dart';
import '../components/word_form.dart';
import '../components/words_table.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/loader.dart';

class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  int? _activeUnitId;
  int? _pendingUnit;

  int? _resolveActive(List<UnitSummary> units) {
    if (units.isEmpty) return null;
    if (_activeUnitId != null && units.any((u) => u.id == _activeUnitId)) {
      return _activeUnitId;
    }
    // Default: the last (currently-filling) part.
    return units.last.id;
  }

  Future<void> _submit(Map<String, dynamic> data) async {
    final res = await api.addVocabularyWord(data);
    _pendingUnit = res.unitId;
  }

  void _onAdded() {
    ref.invalidate(vocabularyProvider);
    ref.invalidate(unitWordsProvider);
    ref.invalidate(booksProvider);
    if (_pendingUnit != null && _pendingUnit != _activeUnitId) {
      setState(() => _activeUnitId = _pendingUnit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final async = ref.watch(vocabularyProvider);
    final isAdmin = ref.watch(isAdminProvider);
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Loader()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: StateCard(
            error: true, child: Text('${ref.tr('common.error')}: $e')),
      ),
      data: (book) {
        final units = book.units;
        final activeId = _resolveActive(units);
        UnitSummary? activeUnit;
        for (final u in units) {
          if (u.id == activeId) {
            activeUnit = u;
            break;
          }
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: () => context.go('/'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back, size: 16, color: c.mutedFg),
                const SizedBox(width: 4),
                Text(ref.tr('common.back_to_books'),
                    style: TextStyle(fontSize: 13, color: c.mutedFg)),
              ]),
            ),
            const SizedBox(height: 8),
            Text(ref.tr('vocab.title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(ref.tr('vocab.subtitle'),
                style: TextStyle(fontSize: 13, color: c.mutedFg)),
            const SizedBox(height: 16),
            if (units.isNotEmpty) ...[
              UnitTabs(
                units: units,
                activeUnitId: activeId,
                onSelect: (id) => setState(() => _activeUnitId = id),
              ),
              const SizedBox(height: 16),
            ],
            if (isAdmin) ...[
              WordForm(submitWord: _submit, onAdded: _onAdded),
              const SizedBox(height: 16),
            ],
            if (activeUnit != null && activeId != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                        ref.tr('vocab.part', {'n': activeUnit.order}),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  Text(ref.tr('book.word_count', {'count': activeUnit.wordCount}),
                      style: TextStyle(fontSize: 13, color: c.mutedFg)),
                ],
              ),
              const SizedBox(height: 12),
              WordsTable(key: ValueKey('vocab-$activeId'), unitId: activeId),
            ] else
              StateCard(child: Text(ref.tr('vocab.empty'))),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
