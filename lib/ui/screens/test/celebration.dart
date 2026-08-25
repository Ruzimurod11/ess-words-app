import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nishon effekti: butun ekran bo'ylab fireworks portlashlari + pastdagi ikki
/// burchakdan otiladigan konfetti. 5 ta ketma-ket to'g'ri javobda ko'rsatiladi.
const Duration kCelebrationDuration = Duration(milliseconds: 2500);

const _palette = [
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF22D3EE),
  Color(0xFFA855F7),
  Color(0xFF22C55E),
  Color(0xFFEF4444),
  Color(0xFF3B82F6),
];

class _Burst {
  final Offset center; // ekran o'lchamiga nisbatan (0..1)
  final Color color;
  final double start; // umumiy progressdagi boshlanish nuqtasi
  final double distance; // zarralarning uchish masofasi (px)
  const _Burst(this.center, this.color, this.start, this.distance);
}

const _bursts = [
  _Burst(Offset(0.18, 0.26), Color(0xFFF59E0B), 0.00, 150),
  _Burst(Offset(0.80, 0.20), Color(0xFFEC4899), 0.07, 170),
  _Burst(Offset(0.50, 0.42), Color(0xFF22D3EE), 0.14, 200),
  _Burst(Offset(0.26, 0.70), Color(0xFFA855F7), 0.21, 160),
  _Burst(Offset(0.76, 0.66), Color(0xFF22C55E), 0.26, 180),
];

const _particlesPerBurst = 16;

/// Har bir zarraga kichik burchak/masofa og'ishi — halqa mukammal doira
/// bo'lib qolmasligi uchun.
final List<(double, double)> _particleJitter = () {
  final rng = math.Random(3);
  return List<(double, double)>.generate(
    _particlesPerBurst,
    (_) => (rng.nextDouble() * 0.5 - 0.25, 0.75 + rng.nextDouble() * 0.45),
  );
}();

class _Confetti {
  final Color color;
  final double dx; // gorizontal siljish (ekran kengligiga nisbatan)
  final double peak; // otilish balandligi (ekran balandligiga nisbatan)
  final double start;
  final double span;
  final double spin;
  final Size size;
  final bool round;
  const _Confetti(this.color, this.dx, this.peak, this.start, this.span,
      this.spin, this.size, this.round);
}

/// Parchalar bir marta — qat'iy urug' bilan — yaratiladi, shunda har bir
/// portlashda traektoriya bir xil va tabiiy tarqoq bo'ladi. Ro'yxatning birinchi
/// yarmi chap, ikkinchisi o'ng to'pga tegishli — shunda ikki tomon bir-birining
/// ko'zgudagi aksiga o'xshab qolmaydi.
final List<_Confetti> _confetti = () {
  final rng = math.Random(7);
  return List<_Confetti>.generate(40, (i) {
    final wide = i % 3 == 0;
    return _Confetti(
      _palette[i % _palette.length],
      0.20 + rng.nextDouble() * 0.60,
      0.30 + rng.nextDouble() * 0.35,
      rng.nextDouble() * 0.18,
      0.62 + rng.nextDouble() * 0.28,
      (2 + rng.nextDouble() * 4) * (rng.nextBool() ? 1 : -1),
      wide ? const Size(8, 8) : const Size(6, 12),
      i % 4 == 0,
    );
  });
}();

class Celebration extends StatefulWidget {
  const Celebration({super.key});

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kCelebrationDuration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _CelebrationPainter(_controller.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double t;
  _CelebrationPainter(this.t);

  double _local(double start, double span) =>
      ((t - start) / span).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    _paintFireworks(canvas, size);
    _paintConfetti(canvas, size, fromLeft: true);
    _paintConfetti(canvas, size, fromLeft: false);
  }

  void _paintFireworks(Canvas canvas, Size size) {
    for (final burst in _bursts) {
      final p = _local(burst.start, 0.55);
      if (p <= 0 || p >= 1) continue;
      final center =
          Offset(burst.center.dx * size.width, burst.center.dy * size.height);

      // portlash yorug'ligi — zarralar tarqalguncha markazda so'nadi
      final flash = _local(burst.start, 0.18);
      if (flash > 0 && flash < 1) {
        canvas.drawCircle(
          center,
          14 + 34 * flash,
          Paint()
            ..color = burst.color.withValues(alpha: 0.5 * (1 - flash))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
        );
      }

      final eased = Curves.easeOutCubic.transform(p);
      final fade = p < 0.12 ? p / 0.12 : 1 - (p - 0.12) / 0.88;
      final paint = Paint()
        ..color = burst.color.withValues(alpha: fade.clamp(0.0, 1.0));
      final glow = Paint()
        ..color = burst.color.withValues(alpha: 0.35 * fade.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      for (var i = 0; i < _particlesPerBurst; i++) {
        final j = _particleJitter[i];
        final angle = (2 * math.pi / _particlesPerBurst) * (i + j.$1);
        final r = burst.distance * eased * j.$2;
        final pos = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        final radius = 4 * (1 - 0.6 * p);
        canvas.drawCircle(pos, radius * 2.2, glow);
        canvas.drawCircle(pos, radius, paint);
      }
    }
  }

  void _paintConfetti(Canvas canvas, Size size, {required bool fromLeft}) {
    final origin = Offset(fromLeft ? size.width * 0.02 : size.width * 0.98,
        size.height);
    final sign = fromLeft ? 1.0 : -1.0;
    final half = _confetti.length ~/ 2;
    final pieces = fromLeft
        ? _confetti.take(half)
        : _confetti.skip(half);
    for (final piece in pieces) {
      final p = _local(piece.start, piece.span);
      if (p <= 0 || p >= 1) continue;
      // gorizontal — tekis, vertikal — avval otilish, keyin tortishish
      final x = origin.dx + sign * piece.dx * size.width * p;
      final peak = piece.peak * size.height;
      final double y;
      if (p <= 0.4) {
        y = origin.dy - peak * Curves.easeOut.transform(p / 0.4);
      } else {
        final f = (p - 0.4) / 0.6;
        y = origin.dy - peak + (peak + size.height * 0.2) * f * f;
      }
      final fade = p < 0.75 ? 1.0 : 1 - (p - 0.75) / 0.25;
      final paint = Paint()
        ..color = piece.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * sign * p * math.pi);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: piece.size.width, height: piece.size.height);
      if (piece.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => old.t != t;
}
