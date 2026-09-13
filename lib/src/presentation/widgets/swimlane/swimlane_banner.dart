import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/twist_colors.dart';
import '../../../theme/twist_music_theme.dart';

/// Header content of the banner style: logo and lane title on the left, the
/// lane subtitle as the offer text on the right, and a download pill.
class SwimlaneBanner extends StatelessWidget {
  const SwimlaneBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onDownload,
    this.logo,
    this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 0),
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onDownload;
  final ImageProvider? logo;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final accent = TwistMusicTheme.of(context).promptAccent ?? TwistColors.accent;
    final forward = Directionality.of(context) == TextDirection.rtl
        ? Iconsax.arrow_left_3
        : Iconsax.arrow_right_3;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logo != null) ...[
                  ExcludeSemantics(
                    child: Image(
                      image: logo!,
                      height: 26,
                      fit: BoxFit.contain,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: TwistColors.onDarkTitle),
                ),
                const SizedBox(height: 16),
                Semantics(
                  identifier: 'twistMusic_swimlaneDownloadBtn',
                  label: ctaLabel,
                  excludeSemantics: true,
                  container: true,
                  button: true,
                  child: GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: TwistColors.onDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ctaLabel,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                          const SizedBox(width: 4),
                          Icon(forward, size: 16, color: accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              subtitle,
              textAlign: TextAlign.end,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: TwistColors.onDark,
                  height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
