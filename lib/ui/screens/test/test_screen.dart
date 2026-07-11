import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/book.dart';
import '../../../models/quiz.dart';
import '../../../state/app_state.dart';
import '../../../state/data.dart';
import '../../components/unit_tabs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';
import 'quiz_game.dart';

/// Immutable snapshot of the test-flow position (mirrors the web query params).
class _TS {
  final String? mode; // 'topic' | 'general'
  final QuizLevel? level;
  final String? scope; // 'all' | 'half' | 'full'
  final int? book, unit, fromBook, fromUnit, toBook, toUnit;
  const _TS({
    this.mode,
    this.level,
    this.scope,
    this.book,
    this.unit,
    this.fromBook,
    this.fromUnit,
    this.toBook,
    this.toUnit,
  });
}

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  _TS s = const _TS();

  void _go(_TS next) => setState(() => s = next);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _body(),
    );
  }

  Widget _body() {
    if (s.mode == 'general') return _generalFlow();

    final level = s.level;
    if (s.mode == 'topic' && level != null) {
      if (s.unit != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(ref.tr('test.${level.value}')),
            const SizedBox(height: 16),
            QuizGame(
              key: ValueKey('${level.value}-${s.unit}'),
              unitId: s.unit,
              level: level,
              onExit: () =>
                  _go(_TS(mode: 'topic', level: level, book: s.book)),
            ),
          ],
        );
      }
      if (s.book != null) {
        return _UnitPicker(
          bookId: s.book!,
          title: ref.tr('test.choose_unit'),
          onSelect: (u) =>
              _go(_TS(mode: 'topic', level: level, book: s.book, unit: u)),
          onBack: () => _go(_TS(mode: 'topic', level: level)),
        );
      }
      return _BookPicker(
        title: ref.tr('test.choose_book'),
        onSelect: (b) => _go(_TS(mode: 'topic', level: level, book: b)),
        onBack: () => _go(const _TS(mode: 'topic')),
      );
    }

    if (s.mode == 'topic') {
      return _levelPicker(
        onSelect: (l) => _go(_TS(mode: 'topic', level: l)),
        onBack: () => _go(const _TS()),
      );
    }

    // root
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(ref.tr('test.title')),
        const SizedBox(height: 16),
        _ChoiceCard(
          title: ref.tr('test.topic'),
          description: ref.tr('test.topic_desc'),
          icon: Icons.menu_book_outlined,
          onTap: () => _go(const _TS(mode: 'topic')),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          title: ref.tr('test.general'),
          description: ref.tr('test.general_desc'),
          icon: Icons.layers_outlined,
          onTap: () => _go(const _TS(mode: 'general')),
        ),
      ],
    );
  }

  Widget _generalFlow() {
    final level = s.level;
    if (level == null) {
      return _levelPicker(
        onSelect: (l) => _go(_TS(mode: 'general', level: l)),
        onBack: () => _go(const _TS()),
      );
    }
    // keep level across every transition inside the flow
    _TS g({
      String? scope,
      int? fromBook,
      int? fromUnit,
      int? toBook,
      int? toUnit,
    }) =>
        _TS(
          mode: 'general',
          level: level,
          scope: scope,
          fromBook: fromBook,
          fromUnit: fromUnit,
          toBook: toBook,
          toUnit: toUnit,
        );

    if (s.scope == 'all') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(ref.tr('test.all_words')),
          const SizedBox(height: 16),
          QuizGame(
            key: ValueKey('all-${level.value}'),
            selectableCount: true,
            level: level,
            onExit: () => _go(g()),
          ),
        ],
      );
    }

    if (s.scope == 'half') {
      if (s.toUnit != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(ref.tr('test.half_manual')),
            const SizedBox(height: 16),
            QuizGame(
              key: ValueKey('half-${level.value}-${s.toUnit}'),
              toUnitId: s.toUnit,
              selectableCount: true,
              level: level,
              onExit: () => _go(g(scope: 'half', toBook: s.toBook)),
            ),
          ],
        );
      }
      if (s.toBook != null) {
        return _UnitPicker(
          bookId: s.toBook!,
          title: ref.tr('test.choose_end_unit'),
          onSelect: (u) => _go(g(scope: 'half', toBook: s.toBook, toUnit: u)),
          onBack: () => _go(g(scope: 'half')),
        );
      }
      return _BookPicker(
        title: ref.tr('test.choose_end_book'),
        onSelect: (b) => _go(g(scope: 'half', toBook: b)),
        onBack: () => _go(g()),
      );
    }

    if (s.scope == 'full') {
      if (s.fromUnit != null && s.toUnit != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(ref.tr('test.full_manual')),
            const SizedBox(height: 16),
            QuizGame(
              key: ValueKey('full-${level.value}-${s.fromUnit}-${s.toUnit}'),
              fromUnitId: s.fromUnit,
              toUnitId: s.toUnit,
              selectableCount: true,
              level: level,
              onExit: () => _go(g(
                  scope: 'full',
                  fromBook: s.fromBook,
                  fromUnit: s.fromUnit,
                  toBook: s.toBook)),
            ),
          ],
        );
      }
      if (s.fromUnit != null && s.toBook != null) {
        return _UnitPicker(
          bookId: s.toBook!,
          title: ref.tr('test.choose_end_unit'),
          onSelect: (u) => _go(g(
              scope: 'full',
              fromBook: s.fromBook,
              fromUnit: s.fromUnit,
              toBook: s.toBook,
              toUnit: u)),
          onBack: () => _go(g(
              scope: 'full', fromBook: s.fromBook, fromUnit: s.fromUnit)),
        );
      }
      if (s.fromUnit != null) {
        return _BookPicker(
          title: ref.tr('test.choose_end_book'),
          onSelect: (b) => _go(g(
              scope: 'full',
              fromBook: s.fromBook,
              fromUnit: s.fromUnit,
              toBook: b)),
          onBack: () => _go(g(scope: 'full', fromBook: s.fromBook)),
        );
      }
      if (s.fromBook != null) {
        return _UnitPicker(
          bookId: s.fromBook!,
          title: ref.tr('test.choose_start_unit'),
          onSelect: (u) =>
              _go(g(scope: 'full', fromBook: s.fromBook, fromUnit: u)),
          onBack: () => _go(g(scope: 'full')),
        );
      }
      return _BookPicker(
        title: ref.tr('test.choose_start_book'),
        onSelect: (b) => _go(g(scope: 'full', fromBook: b)),
        onBack: () => _go(g()),
      );
    }

    // general scope chooser
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onTap: () => _go(const _TS(mode: 'general'))),
        const SizedBox(height: 12),
        _title(ref.tr('test.general')),
        const SizedBox(height: 16),
        _ChoiceCard(
          title: ref.tr('test.all_words'),
          description: ref.tr('test.all_words_desc'),
          icon: Icons.auto_awesome,
          onTap: () => _go(g(scope: 'all')),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          title: ref.tr('test.half_manual'),
          description: ref.tr('test.half_manual_desc'),
          icon: Icons.tune,
          onTap: () => _go(g(scope: 'half')),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          title: ref.tr('test.full_manual'),
          description: ref.tr('test.full_manual_desc'),
          icon: Icons.settings_outlined,
          onTap: () => _go(g(scope: 'full')),
        ),
      ],
    );
  }

  Widget _levelPicker({
    required ValueChanged<QuizLevel> onSelect,
    required VoidCallback onBack,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(height: 12),
        _title(ref.tr('test.choose_level')),
        const SizedBox(height: 16),
        _ChoiceCard(
          title: ref.tr('test.easy'),
          description: ref.tr('test.easy_desc'),
          icon: Icons.checklist,
          onTap: () => onSelect(QuizLevel.easy),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          title: ref.tr('test.hard'),
          description: ref.tr('test.hard_desc'),
          icon: Icons.keyboard_outlined,
          onTap: () => onSelect(QuizLevel.hard),
        ),
      ],
    );
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: kBrandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 14, color: c.mutedFg)),
        ],
      ),
    );
  }
}

class _BackButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.arrow_back, size: 16, color: c.mutedFg),
          const SizedBox(width: 4),
          Text(ref.tr('test.back'),
              style: TextStyle(fontSize: 13, color: c.mutedFg)),
        ]),
      ),
    );
  }
}

class _BookPicker extends ConsumerWidget {
  final String title;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  const _BookPicker({
    required this.title,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(booksProvider);
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Loader(),
          error: (e, _) => StateCard(
              error: true, child: Text('${ref.tr('common.error')}: $e')),
          data: (books) {
            final essential =
                books.where((b) => b.kind == BookKind.essential).toList();
            return Column(
              children: essential.map((book) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => onSelect(book.id),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: bookGradient(book.order),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${book.order}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(book.title,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                  ref.tr('book.word_count',
                                      {'count': book.wordCount}),
                                  style: TextStyle(
                                      fontSize: 12, color: c.mutedFg)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UnitPicker extends ConsumerWidget {
  final int bookId;
  final String title;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  const _UnitPicker({
    required this.bookId,
    required this.title,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookProvider(bookId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Loader(),
          error: (e, _) => StateCard(
              error: true, child: Text('${ref.tr('common.error')}: $e')),
          data: (book) => UnitTabs(
            units: book.units,
            activeUnitId: null,
            onSelect: onSelect,
          ),
        ),
      ],
    );
  }
}
