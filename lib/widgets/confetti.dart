import 'dart:math';

import 'package:flutter/material.dart';

/// Простое конфетти поверх экрана: разноцветные падающие прямоугольники.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.particleCount = 44});

  final int particleCount;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  static const List<Color> _colors = [
    Color(0xFF6C5CE7),
    Color(0xFFFF9F43),
    Color(0xFF00B894),
    Color(0xFFE84393),
    Color(0xFF0984E3),
    Color(0xFFFDCB6E),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random(7);
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        x: rnd.nextDouble(),
        speed: 0.6 + rnd.nextDouble() * 0.9,
        phase: rnd.nextDouble(),
        size: 8 + rnd.nextDouble() * 10,
        color: _colors[rnd.nextInt(_colors.length)],
        spin: (rnd.nextDouble() - 0.5) * 3,
        sway: 10 + rnd.nextDouble() * 26,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.speed,
    required this.phase,
    required this.size,
    required this.color,
    required this.spin,
    required this.sway,
  });

  final double x;
  final double speed;
  final double phase;
  final double size;
  final Color color;
  final double spin;
  final double sway;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (p.phase + t * p.speed) % 1.0;
      final y = progress * (size.height + 40) - 20;
      final x = p.x * size.width + sin(progress * pi * 2) * p.sway;
      final angle = p.spin * progress * pi * 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final paint = Paint()..color = p.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
