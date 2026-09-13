import 'package:flutter/material.dart';

import '../../../data/models/twist_track.dart';
import '../../../theme/twist_colors.dart';
import '../../../theme/twist_music_theme.dart';
import '../twist_artwork.dart';
import 'track_status_badge.dart';

/// Square artwork card with the artist and title over a bottom scrim, and a
/// "Now Playing" capsule while the track plays.
class TrackCard extends StatelessWidget {
  const TrackCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.size = 248,
  });

  final TwistTrack track;
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  static const double radius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = TwistMusicTheme.of(context);
    return Semantics(
      identifier: 'twistMusic_trackCard_${track.id}',
      label: '${track.title} ${track.artistName}',
      excludeSemantics: true,
      container: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(color: TwistColors.cardShadow, blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TwistArtwork(
                    url: track.preferredFullArtworkUrl ?? track.preferredCompactArtworkUrl,
                    size: size,
                    radius: 0,
                    placeholderColor: theme.artworkPlaceholder,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: size * 0.55,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), TwistColors.cardScrim],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: TrackStatusBadge(isPlaying: isPlaying),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.cardArtistStyle),
                        const SizedBox(height: 4),
                        Text(track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.cardTitleStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
