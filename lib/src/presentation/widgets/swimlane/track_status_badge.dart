import 'package:flutter/material.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../equalizer_bars.dart';

/// Bottom-left card badge: "Preview" on a scrim, or "Now Playing" with bars.
class TrackStatusBadge extends StatelessWidget {
  const TrackStatusBadge({super.key, required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    const labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      shadows: [Shadow(color: Color(0x73000000), blurRadius: 2, offset: Offset(0, 1))],
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 120),
      child: isPlaying
          ? Row(
              key: const ValueKey('playing'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const EqualizerBars(
                    barCount: 4, barWidth: 3, spacing: 2, minHeight: 4, maxHeight: 16),
                const SizedBox(width: 5),
                Text(strings.nowPlayingLabel, style: labelStyle),
              ],
            )
          : Container(
              key: const ValueKey('preview'),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: TwistColors.badgeScrim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(strings.previewLabel,
                      style: labelStyle.copyWith(shadows: const [])),
                ],
              ),
            ),
    );
  }
}
