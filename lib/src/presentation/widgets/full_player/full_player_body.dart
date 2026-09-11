import 'package:flutter/material.dart';

import '../../../analytics/twist_analytics.dart';
import '../../../data/playback/twist_playback_snapshot.dart';
import '../../../data/playback/twist_playback_status.dart';
import '../../../theme/twist_colors.dart';
import '../../../twist_music_player_impl.dart';
import '../../../utils/artwork_palette.dart';
import '../preview_badge.dart';
import '../twist_artwork.dart';
import 'full_player_controls.dart';
import 'full_player_promo_card.dart';
import 'full_player_queue_sheet.dart';
import 'full_player_scrub_bar.dart';
import 'full_player_top_bar.dart';

/// The full player's content, shared by the route-based screen and the
/// in-host expansion. Dark and forced left-to-right, as in the native apps.
class TwistFullPlayerBody extends StatelessWidget {
  const TwistFullPlayerBody({
    super.key,
    required this.onCollapse,
    required this.onOpenQueue,
    this.paintBackground = true,
    this.hideArtwork = false,
    this.artworkKey,
  });

  final VoidCallback onCollapse;
  final VoidCallback onOpenQueue;

  /// Paints the artwork-tinted gradient. The in-host expansion paints its own
  /// background on the morphing surface instead.
  final bool paintBackground;

  /// Leaves the artwork slot empty (keeping its size) so a flying artwork can
  /// land on it.
  final bool hideArtwork;

  /// Identifies the artwork slot so its rectangle can be measured.
  final Key? artworkKey;

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    final controller = player.controller;
    final branding = player.config.branding;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<ArtworkPalette>(
        valueListenable: player.artworkPalette,
        builder: (context, palette, child) {
          if (!paintBackground) return child!;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: TwistColors.darkNavy,
              gradient: fullPlayerGradient(palette),
            ),
            child: child,
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: ValueListenableBuilder<TwistPlaybackSnapshot>(
            valueListenable: controller,
            builder: (context, snapshot, _) {
              final track = snapshot.currentTrack;
              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0x59FFFFFF),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FullPlayerTopBar(onCollapse: onCollapse),
                    const SizedBox(height: 8),
                    FullPlayerPromoCard(
                      logo: branding?.promoLogo,
                      onGetApp: () => player.openDownloadLink(
                          source: TwistAnalyticsSources.fullScreenBanner),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final side = constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;
                              return KeyedSubtree(
                                key: artworkKey,
                                child: hideArtwork
                                    ? SizedBox(width: side, height: side)
                                    : TwistArtwork(
                                        url: track?.preferredFullArtworkUrl,
                                        size: side,
                                        radius: 10,
                                        placeholderColor: TwistColors.artworkPlaceholderDark,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            track?.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: TwistColors.onDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            track?.artistName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: TwistColors.onDarkMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FullPlayerScrubBar(
                      progressSeconds: snapshot.progressSeconds,
                      durationSeconds: controller.previewSeconds,
                      onSeek: controller.seek,
                    ),
                    const SizedBox(height: 20),
                    PreviewBadge(isPlaying: snapshot.isPlaying, tint: const Color(0xB3FFFFFF)),
                    const SizedBox(height: 20),
                    FullPlayerControls(
                      isPlaying: snapshot.isPlaying,
                      isLoading: snapshot.status == TwistPlaybackStatus.loading,
                      hasTrack: track != null,
                      onPrevious: controller.previous,
                      onToggle: controller.togglePlayPause,
                      onNext: controller.next,
                    ),
                    const SizedBox(height: 20),
                    FullPlayerQueueButton(visible: snapshot.hasQueue, onPressed: onOpenQueue),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The darkened artwork gradient behind the full player, over a 15 % black
/// wash, as in the native player.
LinearGradient fullPlayerGradient(ArtworkPalette palette) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.alphaBlend(const Color(0x26000000), palette.backgroundTop),
        Color.alphaBlend(const Color(0x26000000), palette.backgroundBottom),
      ],
    );
