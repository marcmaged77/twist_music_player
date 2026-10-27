import 'package:flutter/material.dart';

import '../../../data/models/twist_track.dart';
import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../../../theme/twist_music_theme.dart';
import '../equalizer_bars.dart';
import '../twist_artwork.dart';

/// Coverflow tile: square artwork on a translucent white card, a bottom-left
/// "Now Playing" row over the art while the track plays, and the title and
/// artist under it. On the 375 pt design the tile measures 188 x 236.
class CoverflowTrackCard extends StatelessWidget {
  const CoverflowTrackCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.width = 190,
  });

  final TwistTrack track;
  final bool isPlaying;
  final VoidCallback onTap;
  final double width;

  static const double radius = 20;
  static const double artworkInset = 8;
  static const double artworkTop = 12;
  static const double labelInset = 16;
  static const double labelTop = 10;
  static const double labelGap = 2;
  static const double labelBottom = 8;

  /// Share of the tile's height that sits over the band.
  static const double bandOverlap = 0.22;

  /// Tile height for [width]: the inset square artwork plus the label block.
  static double heightFor(double width, TwistMusicTheme theme) =>
      artworkTop + (width - 2 * artworkInset) + labelsHeightFor(theme);

  static double labelsHeightFor(TwistMusicTheme theme) =>
      labelTop +
      _lineHeight(theme.coverflowTitleStyle, 14) +
      labelGap +
      _lineHeight(theme.coverflowArtistStyle, 12) +
      labelBottom;

  static double _lineHeight(TextStyle? style, double fallbackSize) =>
      (style?.fontSize ?? fallbackSize) * (style?.height ?? 1.2);

  static TextStyle? _withFamily(TextStyle? style, String? family) =>
      style?.fontFamily != null || family == null ? style : (style ?? const TextStyle()).copyWith(fontFamily: family);

  @override
  Widget build(BuildContext context) {
    final theme = TwistMusicTheme.of(context);
    final art = width - 2 * artworkInset;
    return Semantics(
      identifier: 'twistMusic_trackCard_${track.id}',
      label: '${track.title} ${track.artistName}',
      excludeSemantics: true,
      container: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width,
          height: heightFor(width, theme),
          decoration: BoxDecoration(
            color: theme.coverflowCardFill,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(color: TwistColors.coverflowShadow, blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(artworkInset, artworkTop, artworkInset, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius - artworkInset),
                  child: SizedBox(
                    width: art,
                    height: art,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TwistArtwork(
                          url: track.preferredFullArtworkUrl ?? track.preferredCompactArtworkUrl,
                          size: art,
                          radius: 0,
                          placeholderColor: theme.artworkPlaceholder,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _NowPlayingRow(visible: isPlaying),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Host fonts may run taller than the measured block; clip rather than overflow.
              Expanded(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: AlignmentDirectional.topStart,
                    maxHeight: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(labelInset, labelTop, labelInset, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _withFamily(theme.coverflowTitleStyle, theme.fontFamily)),
                          const SizedBox(height: labelGap),
                          Text(track.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _withFamily(theme.coverflowArtistStyle, theme.fontFamily)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bars and "Now Playing" over a bottom scrim; nothing while idle.
class _NowPlayingRow extends StatelessWidget {
  const _NowPlayingRow({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    final family = TwistMusicTheme.of(context).fontFamily;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 120),
      child: !visible
          ? const SizedBox.shrink(key: ValueKey('idle'))
          : Container(
              key: const ValueKey('playing'),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), TwistColors.badgeScrim],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EqualizerBars(
                      barCount: 5, barWidth: 2.5, spacing: 2, minHeight: 4, maxHeight: 14),
                  const SizedBox(width: 8),
                  Text(
                    strings.nowPlayingLabel,
                    style: TextStyle(
                        fontFamily: family,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
