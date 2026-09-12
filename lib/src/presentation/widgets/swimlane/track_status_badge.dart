import 'package:flutter/material.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../equalizer_bars.dart';

/// Top-left "Now Playing" capsule with animated bars; nothing while idle.
class TrackStatusBadge extends StatelessWidget {
  const TrackStatusBadge({super.key, required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 120),
      child: !isPlaying
          ? const SizedBox.shrink(key: ValueKey('idle'))
          : Container(
              key: const ValueKey('playing'),
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: TwistColors.badgeScrim,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EqualizerBars(
                      barCount: 4, barWidth: 2.5, spacing: 2, minHeight: 3, maxHeight: 12),
                  const SizedBox(width: 6),
                  Text(
                    strings.nowPlayingLabel,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
