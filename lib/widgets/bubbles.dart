import 'dart:math';

import 'package:flutter/material.dart';

/// Slowly drifting translucent bubbles over a vertical gradient —
/// the mobile version of the desktop app's animated background.
class BubbleBackground extends StatefulWidget {
  final List<Color> colors;
  final Color bubble;
  final Widget child;
  const BubbleBackground({super.key, required this.colors, required this.bubble, required this.child});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  final _bubbles = List.generate(14, (i) {
    final r = Random(i * 7 + 3);
    return (x: r.nextDouble(), y: r.nextDouble(), r: 18 + r.nextDouble() * 60, s: 0.3 + r.nextDouble());
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.colors,
        ),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(painter: _Painter(_bubbles, _c.value, widget.bubble)),
            ),
          ),
        ),
        widget.child,
      ]),
    );
  }
}

class _Painter extends CustomPainter {
  final List<({double x, double y, double r, double s})> bubbles;
  final double t;
  final Color color;
  _Painter(this.bubbles, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (final b in bubbles) {
      final y = (b.y - t * b.s) % 1.0;
      final x = b.x + sin((t * 2 * pi * b.s) + b.y * 6) * 0.03;
      canvas.drawCircle(Offset(x * size.width, y * (size.height + 2 * b.r) - b.r), b.r, p);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.t != t || old.color != color;
}
