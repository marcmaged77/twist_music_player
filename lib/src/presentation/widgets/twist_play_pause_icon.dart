import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Play/pause glyph that scales and fades between the two states.
class TwistPlayPauseIcon extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(
        isPlaying ? Iconsax.pause5 : Iconsax.play5,
        key: ValueKey<bool>(isPlaying),
        size: size,
        color: color,
      ),
    );
  }
}
