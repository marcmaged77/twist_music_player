import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../l10n/twist_strings.dart';
import 'equalizer_bars.dart';

/// "Preview" label with a play glyph, or animated bars while playing.
class PreviewBadge extends StatelessWidget {
  const PreviewBadge({super.key, required this.isPlaying, this.tint});

  final bool isPlaying;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 12,
          child: Center(
            child: isPlaying
                ? EqualizerBars(barWidth: 2.5, maxHeight: 11, minHeight: 3, color: color)
                : Icon(Iconsax.play5, size: 11, color: color),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          twistStrings(context).previewLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
