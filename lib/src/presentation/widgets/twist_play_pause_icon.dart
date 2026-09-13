import 'package:flutter/material.dart';

/// Play/pause glyph that morphs between the triangle and the bars, as on iOS.
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
    duration: const Duration(milliseconds: 260),
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
    return AnimatedIcon(
      icon: AnimatedIcons.play_pause,
      progress: CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic),
      size: widget.size,
      color: widget.color,
    );
  }
}
