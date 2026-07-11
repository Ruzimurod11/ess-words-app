import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../state/app_state.dart';
import '../../state/data.dart';
import '../components/unit_tabs.dart';
import '../components/word_form.dart';
import '../components/words_table.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(activeUnit.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                        ref.tr('book.word_count', {'count': activeUnit.wordCount}),
                        style: TextStyle(fontSize: 13, color: c.mutedFg)),
                  ],
                ),
                const SizedBox(height: 12),
                if (isAdmin) ...[
                  WordForm(key: ValueKey('form-$activeId'), unitId: activeId),
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
