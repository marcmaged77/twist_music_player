import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/twist_colors.dart';

/// The brand band behind the banner header: the 105° blue to violet to red
/// gradient, with a red glow travelling up and down its right side. A
/// [gradient] override is painted static, and the glow holds still when the
/// platform disables animations.
class BannerBand extends StatefulWidget {
  const BannerBand({
    super.key,
    this.gradient,
    this.topRadius = 20,
    this.bottomBulge = 32,
    this.bottomRadius = 0,
  });

  final Gradient? gradient;

  /// Radius of the two top corners.
  final double topRadius;

  /// How far the oval bottom edge dips at the centre below the side edges.
  /// Zero draws a flat bottom edge instead.
  final double bottomBulge;

  /// Radius of the two bottom corners when the bottom edge is flat.
  final double bottomRadius;

  /// #0021A5 to 55 %, #8A1A6A at 85 %, #EC1C24 at 100 %, at 105°.
  static LinearGradient get brandGradient {
    const angle = 105 * math.pi / 180;
    final dx = math.sin(angle);
    final dy = -math.cos(angle);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: const [
        TwistColors.accent,
        TwistColors.accent,
        TwistColors.bannerViolet,
        TwistColors.bannerRed,
      ],
      stops: const [0, 0.55, 0.85, 1],
    );
  }

  /// The glow at phase [t] in 0..1: a soft red disc on the right third that
  /// rides from the top to the bottom and breathes a little on the way.
  static RadialGradient glow(double t) {
    final y = -0.8 + 1.6 * t;
    final breath = 0.85 + 0.15 * math.sin(t * math.pi);
    return RadialGradient(
      center: Alignment(0.78, y),
      radius: 0.9 * breath,
      colors: const [Color(0xD9EC1C24), Color(0x66C2185B), Color(0x00000000)],
      stops: const [0, 0.45, 1],
    );
  }

  @override
  State<BannerBand> createState() => _BannerBandState();
}

class _BannerBandState extends State<BannerBand> with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final override = widget.gradient;
    final base = DecoratedBox(
      decoration: BoxDecoration(gradient: override ?? BannerBand.brandGradient),
    );
    final Widget band;
    if (override != null) {
      band = base;
    } else if (MediaQuery.disableAnimationsOf(context)) {
      band = Stack(fit: StackFit.expand, children: [
        base,
        DecoratedBox(decoration: BoxDecoration(gradient: BannerBand.glow(0.5))),
      ]);
    } else {
      band = Stack(fit: StackFit.expand, children: [
        base,
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _phase,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: BannerBand.glow(Curves.easeInOut.transform(_phase.value)),
              ),
            ),
          ),
        ),
      ]);
    }
    return ClipPath(
      clipper: BannerBandClipper(
        topRadius: widget.topRadius,
        bottomBulge: widget.bottomBulge,
        bottomRadius: widget.bottomRadius,
      ),
      child: band,
    );
  }
}

/// Rounded top corners and an oval bottom edge that is lowest at the centre,
/// or a flat bottom edge with [bottomRadius] corners when [bottomBulge] is 0.
class BannerBandClipper extends CustomClipper<Path> {
  const BannerBandClipper({
    required this.topRadius,
    required this.bottomBulge,
    this.bottomRadius = 0,
  });

  final double topRadius;
  final double bottomBulge;
  final double bottomRadius;

  @override
  Path getClip(Size size) {
    final r = topRadius;
    final b = bottomBulge;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r));
    if (b > 0) {
      path
        ..lineTo(w, h - b)
        ..quadraticBezierTo(w / 2, h + b, 0, h - b);
    } else if (bottomRadius > 0) {
      final br = bottomRadius;
      path
        ..lineTo(w, h - br)
        ..arcToPoint(Offset(w - br, h), radius: Radius.circular(br))
        ..lineTo(br, h)
        ..arcToPoint(Offset(0, h - br), radius: Radius.circular(br));
    } else {
      path
        ..lineTo(w, h)
        ..lineTo(0, h);
    }
    return path..close();
  }

  @override
  bool shouldReclip(BannerBandClipper old) =>
      old.topRadius != topRadius ||
      old.bottomBulge != bottomBulge ||
      old.bottomRadius != bottomRadius;
}
