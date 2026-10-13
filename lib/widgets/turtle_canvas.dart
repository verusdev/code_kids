import 'package:flutter/material.dart';

import '../python/python_interpreter.dart';

/// Холст, на котором рисует черепашка (команды turtle.forward/right/...).
///
/// Линии рисуются постепенно — как будто черепашка ползёт и оставляет след.
class TurtleCanvas extends StatelessWidget {
  const TurtleCanvas({super.key, required this.segments, this.height = 240});

  final List<TurtleSegment> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBD3E8), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: segments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Черепашка ещё ничего не нарисовала',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8B94A7), fontSize: 14),
                ),
              ),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(
                milliseconds: (300 + segments.length * 120).clamp(400, 4000),
              ),
              builder: (context, value, _) {
                final count =
                    (segments.length * value).round().clamp(0, segments.length);
                return CustomPaint(
                  size: Size.infinite,
                  painter: _TurtlePainter(segments, count),
                );
              },
            ),
    );
  }
}

class _TurtlePainter extends CustomPainter {
  _TurtlePainter(this.segments, this.count);

  final List<TurtleSegment> segments;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = segments.take(count).toList();
    if (visible.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    void upd(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Стартовую точку тоже учитываем, чтобы фигура не «уезжала» в угол.
    upd(segments.first.x1, segments.first.y1);
    for (final s in visible) {
      upd(s.x1, s.y1);
      upd(s.x2, s.y2);
    }

    const pad = 20.0;
    final w = (maxX - minX).abs();
    final h = (maxY - minY).abs();
    final availW = (size.width - pad * 2).clamp(1.0, double.infinity);
    final availH = (size.height - pad * 2).clamp(1.0, double.infinity);
    final double scale;
    if (w < 1e-6 && h < 1e-6) {
      scale = 1.0;
    } else if (w < 1e-6) {
      scale = availH / h;
    } else if (h < 1e-6) {
      scale = availW / w;
    } else {
      scale = (availW / w < availH / h) ? availW / w : availH / h;
    }

    double tx(double x) => pad + (x - minX) * scale + (availW - w * scale) / 2;
    double ty(double y) => pad + (y - minY) * scale + (availH - h * scale) / 2;

    final paint = Paint()
      ..color = const Color(0xFF2D6A4F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(tx(visible.first.x1), ty(visible.first.y1));
    for (final s in visible) {
      path.lineTo(tx(s.x1), ty(s.y1));
      path.lineTo(tx(s.x2), ty(s.y2));
    }
    canvas.drawPath(path, paint);

    // Синяя точка — старт, оранжевая — где черепашка сейчас.
    canvas.drawCircle(
      Offset(tx(segments.first.x1), ty(segments.first.y1)),
      4,
      Paint()..color = const Color(0xFF3776AB),
    );
    canvas.drawCircle(
      Offset(tx(visible.last.x2), ty(visible.last.y2)),
      5,
      Paint()..color = const Color(0xFFE17055),
    );
  }

  @override
  bool shouldRepaint(_TurtlePainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.segments != segments;
}
