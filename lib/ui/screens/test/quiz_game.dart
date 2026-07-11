import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart' as api;
import '../../../core/api_client.dart';
import '../../../core/quiz_logic.dart';
import '../../../models/quiz.dart';
import '../../../state/app_state.dart';
import '../../../state/data.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/loader.dart';

const _feedbackStyles = {
  'perfect': ('👑', [Color(0xFFF59E0B), Color(0xFFEAB308)]),
  'excellent': ('🚀', [Color(0xFF10B981), Color(0xFF14B8A6)]),
  'great': ('🔥', [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
  'good': ('💪', [Color(0xFF0EA5E9), Color(0xFF3B82F6)]),
  'average': ('🌱', [Color(0xFFF97316), Color(0xFFF59E0B)]),
  'low': ('⚡', [Color(0xFFF43F5E), Color(0xFFEC4899)]),
};

const _cheerStyles = {
  'streak': (['🔥', '⚡', '🌟', '🚀', '💎', '👑'], [Color(0xFFF59E0B), Color(0xFFEA580C)]),
  'hot': (['🎉', '⭐', '🤩', '👏'], [Color(0xFF10B981), Color(0xFF14B8A6)]),
  'good': (['💪', '😎', '✨', '🙌'], [Color(0xFF0EA5E9), Color(0xFF3B82F6)]),
  'mid': (['🎯', '🌱', '🧭'], [Color(0xFFF97316), Color(0xFFF59E0B)]),
  'low': (['🧗', '🌤️', '🚴'], [Color(0xFFF43F5E), Color(0xFFEC4899)]),
};

class QuizGame extends ConsumerStatefulWidget {
  final int? unitId;
  final int? fromUnitId;
  final int? toUnitId;
  final bool selectableCount;
  final QuizLevel level;
  final VoidCallback onExit;
  const QuizGame({
    super.key,
    this.unitId,
    this.fromUnitId,
    this.toUnitId,
    this.selectableCount = false,
    this.level = QuizLevel.easy,
    required this.onExit,
  });

  @override
  ConsumerState<QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends ConsumerState<QuizGame> {
  final _rng = math.Random();
  int _index = 0;
  String? _selected;
  String _typed = '';
  final _typedController = TextEditingController();
  List<Answer> _answers = [];
  double _cheerSeed = 0;
  QuizDirection _direction = QuizDirection.uzEn;
  int? _count;
  final _countController = TextEditingController(text: '$kMinCount');
  Future<QuizResponse>? _future;
  Timer? _advanceTimer;

  bool get _hard => widget.level == QuizLevel.hard;

  @override
  void initState() {
    super.initState();
    _count = widget.selectableCount ? null : kMinCount;
    if (_count != null) _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _typedController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _load() {
    _future = api.getQuiz(
      unitId: widget.unitId,
      fromUnitId: widget.fromUnitId,
      toUnitId: widget.toUnitId,
      count: _count ?? kMinCount,
      direction: _direction,
      level: widget.level,
    );
  }

  void _toggleDirection() {
    setState(() {
      _direction =
          _direction == QuizDirection.uzEn ? QuizDirection.enUz : QuizDirection.uzEn;
      _index = 0;
      _selected = null;
      _answers = [];
      _load();
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _selected = null;
      _typed = '';
      _typedController.clear();
      _answers = [];
      _load();
    });
  }

  void _onSelect(QuizQuestion question, String option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      _cheerSeed = _rng.nextDouble();
      _answers = [..._answers, Answer(question, option)];
    });
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(seconds: 1), _next);
  }

  void _next() {
    _advanceTimer?.cancel();
    setState(() {
      _selected = null;
      _typed = '';
      _typedController.clear();
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on language change; all labels below read (not watch) the store
    // because they run inside FutureBuilder/nested builders.
    ref.watch(localeProvider);
    if (_count == null) return _countPicker();
    return FutureBuilder<QuizResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Loader();
        }
        if (snap.hasError || !snap.hasData) {
          final msg = snap.error is ApiException
              ? (snap.error as ApiException).message
              : '${snap.error}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StateCard(
                  error: true, child: Text('${ref.trs('common.error')}: $msg')),
              const SizedBox(height: 16),
              GhostButton(
                  onPressed: widget.onExit, child: Text(ref.trs('test.back'))),
            ],
          );
        }
        final data = snap.data!;
        if (_index >= data.questions.length) return _results(data);
        return _question(data);
      },
    );
  }

  // ---------- count picker ----------
  Widget _countPicker() {
    final books = ref.watch(booksProvider).valueOrNull;
    final maxCount =
        books?.fold<int>(0, (acc, b) => acc + b.wordCount);
    final valid = isValidQuizCount(_countController.text, maxCount);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(ref.trs('test.question_count'),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  if (maxCount != null)
                    Text(
                      ref.trs('test.question_count_hint',
                          {'min': kMinCount, 'max': maxCount}),
                      style:
                          TextStyle(fontSize: 12, color: context.c.mutedFg),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                PrimaryButton(
                  onPressed: valid
                      ? () => setState(() {
                            _count = int.parse(_countController.text.trim());
                            _load();
                          })
                      : null,
                  child: Text(ref.trs('test.start')),
                ),
                const SizedBox(width: 12),
                GhostButton(
                    onPressed: widget.onExit,
                    child: Text(ref.trs('test.back'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- question ----------
  String? _transcriptionFor(QuizResponse data, String text) =>
      data.transcriptions[text.trim().toLowerCase()];

  Widget _question(QuizResponse data) {
    final c = context.c;
    final question = data.questions[_index];
    final answered = _selected != null;
    final answerCorrect =
        _selected != null && isAnswerCorrect(_selected!, question.correct);
    final cheer = answered ? getQuizCheer(_answers) : null;
    final qTrans = _transcriptionFor(data, question.question);

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      ref.trs('test.question_progress', {
                        'current': _index + 1,
                        'total': data.questions.length,
                      }),
                      style: TextStyle(fontSize: 13, color: c.mutedFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _index / data.questions.length,
                          minHeight: 10,
                          backgroundColor: c.muted,
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF7C3AED)),
                        ),
                      ),
                    ),
                    if (!_hard) ...[
                      const SizedBox(width: 12),
                      GhostButton(
                        onPressed: _toggleDirection,
                        child: Text(
                            _direction == QuizDirection.uzEn
                                ? 'UZ - EN'
                                : 'EN - UZ',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(question.question,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold)),
                      if (qTrans != null)
                        Text('[$qTrans]',
                            style: TextStyle(fontSize: 14, color: c.mutedFg)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_hard)
                  _typedAnswer(question, answered, answerCorrect, data)
                else
                  _options(question, answered, data),
                if (answered) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PrimaryButton(
                      onPressed: _next,
                      child: Text(_index + 1 >= data.questions.length
                          ? ref.trs('test.finish')
                          : ref.trs('test.next')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (cheer != null)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: _CheerPopup(cheer: cheer, seed: _cheerSeed)),
          ),
      ],
    );
  }

  Widget _options(QuizQuestion question, bool answered, QuizResponse data) {
    final c = context.c;
    return Column(
      children: question.options.map((option) {
        final trans = _transcriptionFor(data, option);
        Color bg = c.card;
        Color fg = c.foreground;
        Color border = c.border;
        if (answered) {
          if (option == question.correct) {
            bg = const Color(0xFF22C55E);
            fg = Colors.white;
            border = const Color(0xFF22C55E);
          } else if (option == _selected) {
            bg = const Color(0xFFEF4444);
            fg = Colors.white;
            border = const Color(0xFFEF4444);
          } else {
            fg = c.mutedFg;
          }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: answered ? null : () => _onSelect(question, option),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 2),
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(option,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: fg)),
                    ),
                    if (trans != null) ...[
                      const SizedBox(width: 12),
                      Text('[$trans]',
                          style: TextStyle(
                              fontSize: 14,
                              color: fg.withValues(alpha: 0.8))),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typedAnswer(QuizQuestion question, bool answered, bool answerCorrect,
      QuizResponse data) {
    final c = context.c;
    final correctTrans = _transcriptionFor(data, question.correct);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _typedController,
          enabled: !answered,
          autofocus: true,
          textAlign: TextAlign.center,
          hint: ref.trs('test.answer_placeholder'),
          ringColor: answered
              ? (answerCorrect
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444))
              : null,
          onChanged: (v) => setState(() => _typed = v),
          onSubmitted: (_) {
            if (!answered && _typedController.text.trim().isNotEmpty) {
              _onSelect(question, _typedController.text);
            }
          },
        ),
        if (answered) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (answerCorrect ? c.success : c.destructive)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${ref.trs('test.correct_answer')}: ${question.correct}'
              '${correctTrans != null ? '  [$correctTrans]' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: answerCorrect ? c.success : c.destructive),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          PrimaryButton(
            onPressed: _typed.trim().isEmpty
                ? null
                : () => _onSelect(question, _typedController.text),
            child: Text(ref.trs('test.check')),
          ),
        ],
      ],
    );
  }

  // ---------- results ----------
  Widget _results(QuizResponse data) {
    final c = context.c;
    final score = scoreQuiz(_answers);
    final tier = feedbackTierKey(getQuizFeedbackTier(score.percent));
    final style = _feedbackStyles[tier]!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(score.wrong.isEmpty ? Icons.celebration : Icons.emoji_events,
                  color: c.warning, size: 30),
              const SizedBox(width: 12),
              Text(ref.trs('test.results'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ).createShader(r),
                child: Text('${score.percent}%',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: style.$2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style.$1, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.trs('test.feedback.$tier.title'),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(ref.trs('test.feedback.$tier.message'),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _scorePill(
                  ref.trs('test.correct_count', {'count': score.correctCount}),
                  const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _scorePill(
                  ref.trs('test.wrong_count', {'count': score.wrong.length}),
                  const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 16),
          if (score.wrong.isNotEmpty)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(ref.trs('test.wrong_list_title'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Divider(height: 1, color: c.border),
                  for (var i = 0; i < score.wrong.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.border),
                    _wrongRow(score.wrong[i]),
                  ],
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
              ),
              child: Text(ref.trs('test.no_wrong'),
                  style: const TextStyle(color: Color(0xFF16A34A))),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              PrimaryButton(
                onPressed: _restart,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh, size: 16),
                  const SizedBox(width: 6),
                  Text(ref.trs('test.restart')),
                ]),
              ),
              const SizedBox(width: 12),
              GhostButton(
                  onPressed: widget.onExit,
                  child: Text(ref.trs('test.back'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scorePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _wrongRow(Answer a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${ref.trs('test.your_answer')}: ${a.selected}',
              style: const TextStyle(fontSize: 16, color: Color(0xFFEF4444))),
          Text('${ref.trs('test.correct_answer')}: ${a.question.correct}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

class _CheerPopup extends ConsumerWidget {
  final Cheer cheer;
  final double seed;
  const _CheerPopup({required this.cheer, required this.seed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size =
        cheer.isStreak ? kStreakCheerVariants : kCheerTierVariants[cheer.tier]!;
    final variant = math.min((seed * size).floor(), size - 1);
    final styleKey = cheer.isStreak ? 'streak' : cheer.tier;
    final style = _cheerStyles[styleKey]!;
    final message = cheer.isStreak
        ? ref.trs('test.cheer.streak_$variant', {'count': cheer.streak})
        : ref.trs('test.cheer.${cheer.tier}_$variant');
    final emoji = style.$1[variant % style.$1.length];
    return TweenAnimationBuilder<double>(
      key: ValueKey('$styleKey-$variant-$seed'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.6 + 0.4 * t, child: Opacity(opacity: t, child: child)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: style.$2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(message,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
