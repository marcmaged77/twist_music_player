import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Play/pause glyph drawn like the iOS `play.fill` / `pause.fill` symbols:
/// a filled triangle that morphs into two solid bars.
class TwistPlayPauseIcon extends StatefulWidget {
  const TwistPlayPauseIcon({
    super.key,
    required this.isPlaying,
    required this.size,
    required this.color,
  });

  final bool isPlaying;
  final double size;
  final Color color;

  @override
  State<TwistPlayPauseIcon> createState() => _TwistPlayPauseIconState();
}

class _TwistPlayPauseIconState extends State<TwistPlayPauseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.isPlaying ? 1 : 0,
  );

  @override
  void didUpdateWidget(TwistPlayPauseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying == widget.isPlaying) return;
    if (widget.isPlaying) {
      _progress.forward();
    } else {
      _progress.reverse();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: PlayPauseGlyphPainter(progress: curved.value, color: widget.color),
      ),
    );
  }
}

/// Paints the glyph at [progress] 0 (play) to 1 (pause) inside a square.
class PlayPauseGlyphPainter extends CustomPainter {
  const PlayPauseGlyphPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  // The triangle split down its middle so each half can become one bar.
  static const _playLeft = [
    Offset(0.10, 0.04),
    Offset(0.53, 0.27),
    Offset(0.53, 0.73),
    Offset(0.10, 0.96)
  ];
  static const _playRight = [
    Offset(0.53, 0.27),
    Offset(0.96, 0.50),
    Offset(0.96, 0.50),
    Offset(0.53, 0.73)
  ];
  static const _pauseLeft = [
    Offset(0.14, 0.06),
    Offset(0.42, 0.06),
    Offset(0.42, 0.94),
    Offset(0.14, 0.94)
  ];
  static const _pauseRight = [
    Offset(0.58, 0.06),
    Offset(0.86, 0.06),
    Offset(0.86, 0.94),
    Offset(0.58, 0.94)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    // The triangle reads centred when nudged right, as the native symbol is.
    final nudge = Offset(size.width * 0.05 * (1 - t), 0);
    final radius = size.shortestSide * 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rounding = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius
      ..strokeJoin = StrokeJoin.round;
    for (final shape in [_quad(_playLeft, _pauseLeft, t), _quad(_playRight, _pauseRight, t)]) {
      final path = Path();
      for (var i = 0; i < shape.length; i++) {
        final p = Offset(shape[i].dx * size.width, shape[i].dy * size.height) + nudge;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, rounding);
    }
  }

  List<Offset> _quad(List<Offset> from, List<Offset> to, double t) => [
        for (var i = 0; i < 4; i++)
          Offset(lerpDouble(from[i].dx, to[i].dx, t)!, lerpDouble(from[i].dy, to[i].dy, t)!),
      ];

  @override
  bool shouldRepaint(PlayPauseGlyphPainter old) => old.progress != progress || old.color != color;
}
