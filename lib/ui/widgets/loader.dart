import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

const _pairs = [
  {'en': 'book', 'uz': 'kitob', 'ru': 'книга'},
  {'en': 'word', 'uz': "so'z", 'ru': 'слово'},
  {'en': 'learn', 'uz': "o'rganmoq", 'ru': 'учиться'},
  {'en': 'memory', 'uz': 'xotira', 'ru': 'память'},
  {'en': 'dictionary', 'uz': "lug'at", 'ru': 'словарь'},
  {'en': 'knowledge', 'uz': 'bilim', 'ru': 'знание'},
];

Map<String, String> _pairAt(int i) {
  final n = _pairs.length;
  return _pairs[((i % n) + n) % n];
}

/// Flip-card loader mirroring the web Loader: a card rotating on its Y axis,
/// flashing an English word then its translation.
class Loader extends ConsumerStatefulWidget {
  final String? label;
  final bool bare;
  const Loader({super.key, this.label, this.bare = false});

  @override
  ConsumerState<Loader> createState() => _LoaderState();
}

class _LoaderState extends ConsumerState<Loader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => _step++);
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = ref.watch(localeProvider).startsWith('ru') ? 'ru' : 'uz';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final angle = (_step + _ctrl.value) * math.pi;
            final showFront = (angle % (2 * math.pi)) < math.pi / 2 ||
                (angle % (2 * math.pi)) > 3 * math.pi / 2;
            final front = _pairAt((_step ~/ 2));
            final back = _pairAt(((_step - 1) ~/ 2));
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showFront
                  ? _face(c, 'en', front['en']!, front: true)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _face(c, lang, back[lang]!, front: false),
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          widget.label ?? ref.tr('common.loading'),
          style: TextStyle(fontSize: 14, color: c.mutedFg),
        ),
      ],
    );
    if (widget.bare) return content;
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Center(child: content),
    );
  }

  Widget _face(AppColors c, String label, String word, {required bool front}) {
    return Container(
      height: 96,
      width: 176,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: front ? c.card : null,
        gradient: front
            ? null
            : const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: front ? Border.all(color: c.border) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: front ? c.mutedFg : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            word,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: front ? c.foreground : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
