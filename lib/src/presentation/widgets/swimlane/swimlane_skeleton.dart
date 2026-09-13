import 'package:flutter/material.dart';

import '../../../theme/twist_colors.dart';
import 'banner_band.dart';

/// Loading placeholder mirroring the header and the centered card row, with
/// a sweep. [banner] mirrors the banner style: a band the cards overlap.
class SwimlaneSkeleton extends StatefulWidget {
  const SwimlaneSkeleton({
    super.key,
    this.cardWidth = 248,
    this.spacing = 2,
    this.banner = false,
  });

  final double cardWidth;
  final double spacing;
  final bool banner;

  @override
  State<SwimlaneSkeleton> createState() => _SwimlaneSkeletonState();
}

class _SwimlaneSkeletonState extends State<SwimlaneSkeleton> with SingleTickerProviderStateMixin {
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
    // One fixed neutral, whatever the host theme, so the lane loads the same everywhere.
    const base = TwistColors.skeletonBase;
    const highlight = TwistColors.skeletonHighlight;
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
              colors: const [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.banner ? _bannerLayout(base) : _plainLayout(base),
    );
  }

  Widget _plainLayout(Color base) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Block(width: 60, height: 24, radius: 6, color: base),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(width: 140, height: 18, radius: 4, color: base),
                  const SizedBox(height: 6),
                  _Block(width: 180, height: 24, radius: 12, color: base),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _cards(base),
      ],
    );
  }

  Widget _bannerLayout(Color base) {
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 0,
          bottom: widget.cardWidth * 0.6,
          child: ClipPath(
            clipper: const BannerBandClipper(topRadius: 20, bottomBulge: 32),
            child: ColoredBox(color: base),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 22, 36, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Block(width: 70, height: 26, radius: 6, color: base),
                  const SizedBox(height: 8),
                  _Block(width: 150, height: 13, radius: 4, color: base),
                  const SizedBox(height: 16),
                  _Block(width: 140, height: 36, radius: 18, color: base),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _cards(base),
          ],
        ),
      ],
    );
  }

  Widget _cards(Color base) {
    return SizedBox(
      height: widget.cardWidth,
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: widget.spacing + widget.cardWidth * 0.05),
                Transform.scale(
                  scale: i == 1 ? 1 : 0.9,
                  child: _Block(
                      width: widget.cardWidth, height: widget.cardWidth, radius: 16, color: base),
                ),
              ],
            ],
          ),
        ),
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
