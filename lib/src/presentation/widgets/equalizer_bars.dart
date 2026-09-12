import 'package:flutter/material.dart';

/// Bouncing bars shown while a track plays. Static mid-height bars when
/// [animate] is false or animations are disabled.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.barCount = 3,
    this.barWidth = 3,
    this.spacing = 2,
    this.minHeight = 4,
    this.maxHeight = 14,
    this.color = Colors.white,
    this.animate = true,
  });

  final int barCount;
  final double barWidth;
  final double spacing;
  final double minHeight;
  final double maxHeight;
  final Color color;
  final bool animate;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.barCount; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing),
                Container(
                  width: widget.barWidth,
                  height: _heightFor(i),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  double _heightFor(int index) {
    if (!widget.animate) {
      return (widget.minHeight + widget.maxHeight) / 2;
    }
    final phase = (_controller.value + index * 0.33) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final eased = Curves.easeInOut.transform(wave);
    return widget.minHeight + (widget.maxHeight - widget.minHeight) * eased;
  }
}
