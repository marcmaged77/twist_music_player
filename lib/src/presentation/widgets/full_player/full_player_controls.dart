import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../twist_play_pause_icon.dart';

/// Previous, the 72-pt play/pause disc, next.
class FullPlayerControls extends StatelessWidget {
  const FullPlayerControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.hasTrack,
    required this.onPrevious,
    required this.onToggle,
    required this.onNext,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool hasTrack;
  final VoidCallback onPrevious;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  static const double playPauseSize = 72;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    final sideColor = hasTrack ? TwistColors.onDark : TwistColors.onDarkFaint;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SideButton(
          identifier: 'twistMusic_fullPlayerPreviousBtn',
          label: strings.previousTrack,
          icon: Iconsax.previous5,
          color: sideColor,
          onPressed: hasTrack ? onPrevious : null,
        ),
        const SizedBox(width: 48),
        Semantics(
          identifier: 'twistMusic_fullPlayerPlayPauseBtn',
          label: isPlaying ? strings.pauseAction : strings.playAction,
          excludeSemantics: true,
          container: true,
          button: true,
          enabled: hasTrack && !isLoading,
          child: GestureDetector(
            onTap: hasTrack && !isLoading ? onToggle : null,
            child: Container(
              width: playPauseSize,
              height: playPauseSize,
              decoration: const BoxDecoration(
                color: TwistColors.onDark,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : Center(
                      child:
                          TwistPlayPauseIcon(isPlaying: isPlaying, size: 30, color: Colors.black),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 48),
        _SideButton(
          identifier: 'twistMusic_fullPlayerNextBtn',
          label: strings.nextTrack,
          icon: Iconsax.next5,
          color: sideColor,
          onPressed: hasTrack ? onNext : null,
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.identifier,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String identifier;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      label: label,
      excludeSemantics: true,
      container: true,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, size: 28, color: color),
        ),
      ),
    );
  }
}
