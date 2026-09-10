import 'package:flutter/material.dart';

import '../../../data/models/twist_track.dart';
import '../../../theme/twist_music_theme.dart';
import '../twist_artwork.dart';
import 'track_status_badge.dart';

/// Square artwork with a status badge, then artist and title.
class TrackCard extends StatelessWidget {
  const TrackCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.artworkSize = 248,
  });

  final TwistTrack track;
  final bool isPlaying;
  final VoidCallback onTap;
  final double artworkSize;

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
        child: SizedBox(
          width: artworkSize,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  TwistArtwork(
                    url: track.preferredFullArtworkUrl ?? track.preferredCompactArtworkUrl,
                    size: artworkSize,
                    radius: 16,
                    placeholderColor: theme.artworkPlaceholder,
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: TrackStatusBadge(isPlaying: isPlaying),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardArtistStyle),
              const SizedBox(height: 2),
              Text(track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardTitleStyle),
            ],
          ),
        ),
      ),
    );
  }
}
