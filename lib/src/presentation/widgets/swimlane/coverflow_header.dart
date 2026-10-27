import 'package:flutter/material.dart';

import '../../../theme/twist_colors.dart';
import '../../../theme/twist_music_theme.dart';

/// Header content of the coverflow style: the wordmark and a translucent
/// download pill on one line, then the lane title in caps and the offer text.
/// Sizes follow the design, drawn for a 375 pt phone, scaled to [bandWidth].
class CoverflowHeader extends StatelessWidget {
  const CoverflowHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onDownload,
    required this.bandWidth,
    this.logo,
    this.bandInset = 16,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onDownload;
  final ImageProvider? logo;

  /// Width of the band the header sits on, and the band's distance from the
  /// lane's edges.
  final double bandWidth;
  final double bandInset;

  /// Band width of the design the sizes below were measured on.
  static const double designBandWidth = 337.5;

  /// Scale from the design to [bandWidth], kept within sane bounds.
  static double scaleFor(double bandWidth) => (bandWidth / designBandWidth).clamp(0.9, 1.35);

  @override
  Widget build(BuildContext context) {
    final s = scaleFor(bandWidth);
    final family = TwistMusicTheme.of(context).fontFamily;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(bandInset + 16 * s, 16 * s, bandInset + 16 * s, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: logo == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ExcludeSemantics(
                          child: Image(image: logo!, height: 38 * s, fit: BoxFit.contain),
                        ),
                      ),
              ),
              SizedBox(width: 12 * s),
              _DownloadPill(label: ctaLabel, onTap: onDownload, scale: s, fontFamily: family),
            ],
          ),
          SizedBox(height: 22 * s),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: family,
              fontSize: 14.5 * s,
              fontWeight: FontWeight.w500,
              color: TwistColors.onDark,
              letterSpacing: 0.5 * s,
              height: 1.2,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: family,
              fontSize: 11 * s,
              fontWeight: FontWeight.w500,
              color: TwistColors.onDarkTitle,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadPill extends StatelessWidget {
  const _DownloadPill({
    required this.label,
    required this.onTap,
    required this.scale,
    required this.fontFamily,
  });

  final String label;
  final VoidCallback onTap;
  final double scale;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    // Design: 15 pt corners, translucent white fill, 1 pt white inner stroke,
    // a white inner glow (0 / 3 / 6) and a soft drop shadow (0 / 3 / 6).
    // The inner glow is a top-edge gradient, since Flutter has no inset shadow.
    final radius = BorderRadius.circular(15 * scale);
    return Semantics(
      identifier: 'twistMusic_swimlaneDownloadBtn',
      label: label,
      excludeSemantics: true,
      container: true,
      button: true,
      // Own transparent Material so the ripple works above the host's Navigator;
      // the ripple paints over the fill and under the translucent highlight.
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TwistColors.chipFill,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: TwistColors.chipShadow, offset: Offset(0, 3), blurRadius: 6),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: TwistColors.chipSplash,
            highlightColor: TwistColors.chipHighlight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 5.5 * scale),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: TwistColors.chipBorder, width: 1),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [TwistColors.chipHighlight, Color(0x00FFFFFF)],
                  stops: [0, 0.45],
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  // Fixed by design: the label stays 15 pt on every phone.
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: TwistColors.onDark,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
