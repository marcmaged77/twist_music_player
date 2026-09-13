import 'package:flutter/material.dart';

import '../../../theme/twist_colors.dart';
import 'banner_band.dart';
import 'track_card.dart';

/// Loading placeholder that mirrors the loaded lane: the same white
/// containers (band or header, cards) with grey lines inside where the
/// content will be. Only the grey lines shimmer.
class SwimlaneSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) => banner ? _bannerLayout() : _plainLayout();

  Widget _plainLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _Shimmer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(width: 70, height: 24, radius: 6),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(width: 160, height: 18),
                    SizedBox(height: 8),
                    _Line(width: 190, height: 24, radius: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _cards(),
      ],
    );
  }

  Widget _bannerLayout() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 0,
          bottom: cardWidth * 0.6,
          child: const _Container(
            color: TwistColors.skeletonBand,
            clipper: BannerBandClipper(topRadius: 20, bottomBulge: 32),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(36, 22, 36, 0),
              child: _Shimmer(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Line(width: 70, height: 26, radius: 6),
                          SizedBox(height: 8),
                          _Line(width: 150, height: 13),
                          SizedBox(height: 16),
                          _Line(width: 140, height: 36, radius: 18),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Line(width: 140, height: 15),
                          SizedBox(height: 6),
                          _Line(width: 100, height: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _cards(),
          ],
        ),
      ],
    );
  }

  /// Three cards laid out like the carousel: the middle one full size, the
  /// neighbours at 90 % peeking in from the edges.
  Widget _cards() {
    return SizedBox(
      height: cardWidth,
      child: ClipRect(
        clipper: const _SidesClipper(),
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: spacing + cardWidth * 0.05),
                Transform.scale(scale: i == 1 ? 1 : 0.9, child: _card()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return SizedBox(
      width: cardWidth,
      height: cardWidth,
      child: _Container(
        radius: TrackCard.radius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                    child: _Line(width: double.infinity, height: double.infinity, radius: 10)),
                const SizedBox(height: 12),
                const _Line(width: 90, height: 13),
                const SizedBox(height: 6),
                _Line(width: cardWidth * 0.6, height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A solid white container with the loaded content's shape.
class _Container extends StatelessWidget {
  const _Container({
    this.child,
    this.radius,
    this.clipper,
    this.color = TwistColors.skeletonSurface,
  });

  final Widget? child;
  final double? radius;
  final CustomClipper<Path>? clipper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius == null ? null : BorderRadius.circular(radius!),
        border: radius == null ? null : Border.all(color: TwistColors.skeletonBorder, width: 0.5),
      ),
      child: child ?? const SizedBox.expand(),
    );
    return clipper == null ? box : ClipPath(clipper: clipper, child: box);
  }
}

/// Grey placeholder line or block.
class _Line extends StatelessWidget {
  const _Line({required this.width, required this.height, this.radius = 4});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: TwistColors.skeletonBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// A light sweep across the grey lines only, never the white containers.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final t = _controller.value;
          return LinearGradient(
            begin: Alignment(-1 + 3 * t - 1, 0),
            end: Alignment(-1 + 3 * t + 1, 0),
            colors: const [
              TwistColors.skeletonBase,
              TwistColors.skeletonHighlight,
              TwistColors.skeletonBase,
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Clips the card row at the sides only.
class _SidesClipper extends CustomClipper<Rect> {
  const _SidesClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, -40, size.width, size.height + 40);

  @override
  bool shouldReclip(_SidesClipper oldClipper) => false;
}
