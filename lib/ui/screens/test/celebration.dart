import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 5 ta ketma-ket to'g'ri javob nishoni. Web versiyasi (canvas-confetti) bilan
/// bir xil ketma-ketlik: markazdan katta portlash, oltin yulduzli yaltiroq,
/// pastki burchaklardan ikki to'lqin yon to'plar, emoji yomg'iri va ekran
/// bo'ylab tasodifiy portlashlar oqimi.
const Duration kCelebrationDuration = Duration(milliseconds: 2500);

const _base = <Color>[
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFEAB308),
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFFA855F7),
  Color(0xFFEC4899),
];

const _gold = <Color>[
  Color(0xFFFDE68A),
  Color(0xFFFBBF24),
  Color(0xFFF59E0B),
  Color(0xFFFFF7ED),
];

const _emojis = <String>['🎉', '🎊', '✨', '⭐', '🥳', '🎁', '🏆', '💫'];

/// Tasodifiy portlashlar oqimi shuncha davom etadi; QuizGame effektni
/// kCelebrationDuration dan keyin olib tashlaydi.
const _streamMs = 1500.0;
const _streamGapMs = 170.0;
const _msPerTick = 1000 / 60;

enum _Shape { mixed, star, emoji }

/// Bitta otish (canvas-confetti `confetti(opts)` chaqiruvi) tavsifi.
class _Spec {
  final double at; // effekt boshidan necha ms keyin otiladi
  final int count;
  final double angle;
  final double spread;
  final double startVelocity;
  final double decay;
  final double gravity;
  final int ticks;
  final double scalar;
  final Offset origin; // ekran o'lchamiga nisbatan (0..1)
  final List<Color> colors;
  final _Shape shape;

  const _Spec({
    this.at = 0,
    required this.count,
    this.angle = 90,
    this.spread = 45,
    this.startVelocity = 45,
    this.decay = 0.9,
    this.gravity = 1,
    this.ticks = 200,
    this.scalar = 1,
    required this.origin,
    this.colors = _base,
    this.shape = _Shape.mixed,
  });
}

const _schedule = <_Spec>[
  // 1. markaziy portlash
  _Spec(
    count: 120,
    spread: 110,
    startVelocity: 50,
    scalar: 1.1,
    origin: Offset(0.5, 0.55),
  ),
  // 2. oltin yulduzli yaltiroq — asosiy portlash ustidan uchadi
  _Spec(
    count: 45,
    spread: 130,
    startVelocity: 38,
    gravity: 0.6,
    decay: 0.92,
    scalar: 1.3,
    origin: Offset(0.5, 0.55),
    colors: _gold,
    shape: _Shape.star,
  ),
  // 3. pastki burchaklardan yon to'plar (ikki to'lqin) va emoji yomg'iri
  _Spec(
    at: 120,
    count: 70,
    angle: 60,
    spread: 70,
    startVelocity: 55,
    origin: Offset(0, 0.7),
  ),
  _Spec(
    at: 150,
    count: 26,
    spread: 120,
    startVelocity: 35,
    gravity: 0.7,
    ticks: 220,
    scalar: 2,
    origin: Offset(0.5, 0.6),
    shape: _Shape.emoji,
  ),
  _Spec(
    at: 220,
    count: 70,
    angle: 120,
    spread: 70,
    startVelocity: 55,
    origin: Offset(1, 0.7),
  ),
  _Spec(
    at: 700,
    count: 12,
    spread: 120,
    startVelocity: 35,
    gravity: 0.7,
    ticks: 220,
    scalar: 2,
    origin: Offset(0.2, 0.6),
    shape: _Shape.emoji,
  ),
  _Spec(
    at: 780,
    count: 12,
    spread: 120,
    startVelocity: 35,
    gravity: 0.7,
    ticks: 220,
    scalar: 2,
    origin: Offset(0.8, 0.6),
    shape: _Shape.emoji,
  ),
  _Spec(
    at: 900,
    count: 45,
    angle: 60,
    spread: 70,
    startVelocity: 55,
    origin: Offset(0, 0.7),
  ),
  _Spec(
    at: 1000,
    count: 45,
    angle: 120,
    spread: 70,
    startVelocity: 55,
    origin: Offset(1, 0.7),
  ),
];

/// Bitta zarra. Fizika canvas-confetti bilan bir xil: har tikda tezlik
/// `decay` ga qisqaradi, `gravity` esa pastga qat'iy siljish beradi.
class _Fetti {
  double x;
  double y;
  double wobble;
  final double wobbleSpeed;
  double velocity;
  final double angle2D;
  double tiltAngle;
  final double decay;
  final double gravity;
  final double scalar;
  final int totalTicks;
  final Color color;
  final _Shape shape;
  final int variant; // kvadrat/doira tanlovi yoki emoji indeksi

  double wobbleX = 0;
  double wobbleY = 0;
  double tiltSin = 0;
  double tiltCos = 0;
  double random = 2;
  int tick = 0;
  double progress = 0;

  _Fetti({
    required this.x,
    required this.y,
    required this.wobble,
    required this.wobbleSpeed,
    required this.velocity,
    required this.angle2D,
    required this.tiltAngle,
    required this.decay,
    required this.gravity,
    required this.scalar,
    required this.totalTicks,
    required this.color,
    required this.shape,
    required this.variant,
  });

  void advance(math.Random rng) {
    x += math.cos(angle2D) * velocity;
    y += math.sin(angle2D) * velocity + gravity;
    velocity *= decay;

    wobble += wobbleSpeed;
    wobbleX = x + (10 * scalar) * math.cos(wobble);
    wobbleY = y + (10 * scalar) * math.sin(wobble);
    tiltAngle += 0.1;
    tiltSin = math.sin(tiltAngle);
    tiltCos = math.cos(tiltAngle);
    random = rng.nextDouble() + 2;

    progress = tick / totalTicks;
    tick++;
  }

  bool get dead => tick >= totalTicks;
}

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
  )..addListener(_step);

  final _rng = math.Random();
  final _fettis = <_Fetti>[];
  late final List<ui.Image> _emojiImages =
      _emojis.map((e) => _rasterize(e, 22)).toList();

  Size _size = Size.zero;
  bool _started = false;
  int _tick = 0;
  int _nextSpec = 0;
  double _lastStreamShot = -_streamGapMs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _size = MediaQuery.sizeOf(context);
    if (_started) return;
    _started = true;
    // tizimda animatsiya o'chirilgan bo'lsa (a11y) hech narsa chizilmaydi
    if (!MediaQuery.disableAnimationsOf(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final image in _emojiImages) {
      image.dispose();
    }
    super.dispose();
  }

  void _step() {
    final now = _controller.value * kCelebrationDuration.inMilliseconds;

    while (_nextSpec < _schedule.length && _schedule[_nextSpec].at <= now) {
      _emit(_schedule[_nextSpec++]);
    }

    // ekranning yuqori yarmi bo'ylab tasodifiy portlashlar oqimi
    if (now <= _streamMs && now - _lastStreamShot >= _streamGapMs) {
      _lastStreamShot = now;
      _emit(_Spec(
        count: 22,
        spread: 360,
        startVelocity: 22,
        ticks: 120,
        scalar: 0.9,
        origin: Offset(
          0.12 + _rng.nextDouble() * 0.76,
          _rng.nextDouble() * 0.5,
        ),
      ));
    }

    // kadr tushib qolsa ham fizika bir xil tezlikda yursin
    final target = (now / _msPerTick).floor();
    var steps = math.min(target - _tick, 3);
    while (steps-- > 0) {
      for (final fetti in _fettis) {
        fetti.advance(_rng);
      }
      _fettis.removeWhere((f) => f.dead);
    }
    _tick = target;
  }

  void _emit(_Spec spec) {
    if (_size.isEmpty) return;
    final radAngle = spec.angle * math.pi / 180;
    final radSpread = spec.spread * math.pi / 180;
    for (var i = 0; i < spec.count; i++) {
      _fettis.add(_Fetti(
        x: spec.origin.dx * _size.width,
        y: spec.origin.dy * _size.height,
        wobble: _rng.nextDouble() * 10,
        wobbleSpeed: math.min(0.11, _rng.nextDouble() * 0.1 + 0.05),
        velocity:
            spec.startVelocity * 0.5 + _rng.nextDouble() * spec.startVelocity,
        angle2D: -radAngle + (0.5 * radSpread - _rng.nextDouble() * radSpread),
        tiltAngle: (_rng.nextDouble() * 0.5 + 0.25) * math.pi,
        decay: spec.decay,
        gravity: spec.gravity * 3,
        scalar: spec.scalar,
        totalTicks: spec.ticks,
        color: spec.colors[i % spec.colors.length],
        shape: spec.shape,
        variant:
            spec.shape == _Shape.emoji ? i % _emojis.length : _rng.nextInt(2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _CelebrationPainter(_fettis, _emojiImages),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Emoji har kadrda TextPainter bilan chizilmasligi uchun bir marta rasmga
/// aylantiriladi.
ui.Image _rasterize(String text, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
    textDirection: TextDirection.ltr,
  )..layout();
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Offset.zero);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(
    math.max(1, painter.width.ceil()),
    math.max(1, painter.height.ceil()),
  );
  picture.dispose();
  painter.dispose();
  return image;
}

class _CelebrationPainter extends CustomPainter {
  final List<_Fetti> fettis;
  final List<ui.Image> emojiImages;

  _CelebrationPainter(this.fettis, this.emojiImages);

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fettis) {
      final alpha = (1 - f.progress).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final paint = Paint()..color = f.color.withValues(alpha: alpha);

      final x1 = f.x + f.random * f.tiltCos;
      final y1 = f.y + f.random * f.tiltSin;
      final x2 = f.wobbleX + f.random * f.tiltCos;
      final y2 = f.wobbleY + f.random * f.tiltSin;

      switch (f.shape) {
        case _Shape.star:
          _paintStar(canvas, f, paint);
        case _Shape.emoji:
          _paintEmoji(canvas, f, alpha, x1, y1, x2, y2);
        case _Shape.mixed:
          if (f.variant == 0) {
            canvas.drawPath(
              Path()
                ..moveTo(f.x, f.y)
                ..lineTo(f.wobbleX, y1)
                ..lineTo(x2, y2)
                ..lineTo(x1, f.wobbleY)
                ..close(),
              paint,
            );
          } else {
            canvas.save();
            canvas.translate(f.x, f.y);
            canvas.rotate(math.pi / 10 * f.wobble);
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset.zero,
                width: (x2 - x1).abs(),
                height: (y2 - y1).abs(),
              ),
              paint,
            );
            canvas.restore();
          }
      }
    }
  }

  void _paintStar(Canvas canvas, _Fetti f, Paint paint) {
    const spikes = 5;
    const step = math.pi / spikes;
    final inner = 4 * f.scalar;
    final outer = 8 * f.scalar;
    var rot = math.pi / 2 * 3;
    final path = Path();
    for (var i = 0; i < spikes; i++) {
      path.lineTo(f.x + math.cos(rot) * outer, f.y + math.sin(rot) * outer);
      rot += step;
      path.lineTo(f.x + math.cos(rot) * inner, f.y + math.sin(rot) * inner);
      rot += step;
    }
    canvas.drawPath(path..close(), paint);
  }

  void _paintEmoji(Canvas canvas, _Fetti f, double alpha, double x1, double y1,
      double x2, double y2) {
    final image = emojiImages[f.variant];
    // wobble emojini aylantiradi va siqadi — varaqdek qalqib tushadi
    final scaleX = (x2 - x1).abs() * 0.1;
    final scaleY = (y2 - y1).abs() * 0.1;
    if (scaleX <= 0.01 || scaleY <= 0.01) return;
    canvas.save();
    canvas.translate(f.x, f.y);
    canvas.rotate(math.pi / 10 * f.wobble);
    canvas.scale(scaleX, scaleY);
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, w, h),
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => true;
}
