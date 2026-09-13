import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/twist_colors.dart';
import '../../../theme/twist_music_theme.dart';

/// Logo on the title's line, the lane title, and the subtitle as a promo chip
/// that opens the download link.
class SwimlaneHeader extends StatelessWidget {
  const SwimlaneHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logo,
    this.onPromoTap,
  });

  final String title;
  final String subtitle;
  final ImageProvider? logo;

  /// Tap on the promo chip. Null renders the subtitle as plain text.
  final VoidCallback? onPromoTap;

  @override
  Widget build(BuildContext context) {
    final theme = TwistMusicTheme.of(context);
    final titleSize = theme.headerTitleStyle?.fontSize ?? 20;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo != null) ...[
            // Sized to the title's line and nudged down onto its cap height.
            Padding(
              padding: EdgeInsets.only(top: titleSize * 0.12),
              child: ExcludeSemantics(
                child: Image(image: logo!, height: titleSize * 1.2, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.headerTitleStyle),
                const SizedBox(height: 6),
                if (onPromoTap == null)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.headerSubtitleStyle)
                else
                  _PromoChip(
                    label: subtitle,
                    color: theme.promptAccent ?? TwistColors.accent,
                    baseStyle: theme.headerSubtitleStyle,
                    onTap: onPromoTap!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.label,
    required this.color,
    required this.baseStyle,
    required this.onTap,
  });

  final String label;
  final Color color;
  final TextStyle? baseStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = (baseStyle ?? const TextStyle())
        .copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: color, height: 1.2);
    final forward = Directionality.of(context) == TextDirection.rtl
        ? Iconsax.arrow_left_3
        : Iconsax.arrow_right_3;
    return Semantics(
      identifier: 'twistMusic_swimlanePromoBtn',
      label: label,
      excludeSemantics: true,
      container: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.gift, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
              ),
              const SizedBox(width: 4),
              Icon(forward, size: 13, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
