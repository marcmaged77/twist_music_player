import 'package:flutter/material.dart';

/// Loading placeholder mirroring the header and three cards, with a sweep.
class SwimlaneSkeleton extends StatefulWidget {
  const SwimlaneSkeleton({super.key, this.cardWidth = 248, this.spacing = 16});

  final double cardWidth;
  final double spacing;

  @override
  State<SwimlaneSkeleton> createState() => _SwimlaneSkeletonState();
}

class _SwimlaneSkeletonState extends State<SwimlaneSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 + 3 * t - 1, 0),
              end: Alignment(-1 + 3 * t + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Block(width: 60, height: 30, radius: 6, color: base),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Block(width: 140, height: 18, radius: 4, color: base),
                    const SizedBox(height: 6),
                    _Block(width: 100, height: 12, radius: 4, color: base),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: widget.cardWidth + 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => SizedBox(width: widget.spacing),
              itemBuilder: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(
                      width: widget.cardWidth,
                      height: widget.cardWidth,
                      radius: 16,
                      color: base),
                  const SizedBox(height: 8),
                  _Block(width: 90, height: 12, radius: 4, color: base),
                  const SizedBox(height: 6),
                  _Block(width: 160, height: 15, radius: 4, color: base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
