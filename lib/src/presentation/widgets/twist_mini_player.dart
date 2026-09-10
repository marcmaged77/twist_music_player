import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/playback/twist_playback_snapshot.dart';
import '../../data/playback/twist_playback_status.dart';
import '../../l10n/twist_strings.dart';
import '../../theme/twist_music_theme.dart';
import '../../twist_music_player_impl.dart';
import 'preview_badge.dart';
import 'twist_artwork.dart';
import 'twist_prompt_listener.dart';

/// The 56-pt capsule: artwork, title, preview badge, play/pause and close.
/// Renders nothing while no track is loaded, so it can live in the tree
/// permanently. The host positions it.
class TwistMiniPlayer extends StatelessWidget {
  const TwistMiniPlayer({super.key, this.onExpand, this.height = 56});

  /// Replaces the default tap behaviour (opening the full player).
  final VoidCallback? onExpand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    return ValueListenableBuilder<TwistPlaybackSnapshot>(
      valueListenable: player.controller,
      builder: (context, snapshot, _) {
        final track = snapshot.currentTrack;
        if (!snapshot.isActive || track == null) return const SizedBox.shrink();
        final strings = twistStrings(context);
        final theme = TwistMusicTheme.of(context);
        final foreground = theme.miniPlayerForeground ?? Theme.of(context).colorScheme.onSurface;
        final loading = snapshot.status == TwistPlaybackStatus.loading;

        return TwistPromptListener(
          child: Semantics(
            identifier: 'twistMusic_miniPlayerExpandBtn',
            label: strings.miniPlayerExpand,
            container: true,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpand ??
                  () => player.openFullPlayer(
                        context,
                        analyticsVia: 'tap',
                        expandFrom: _globalRect(context),
                      ),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: ColoredBox(
                      color: theme.miniPlayerBackground ?? const Color(0xB8FFFFFF),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: TwistArtwork(
                                url: track.preferredFullArtworkUrl,
                                size: 44,
                                radius: 10,
                                placeholderColor: theme.artworkPlaceholder,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.miniPlayerTitleStyle),
                                  const SizedBox(height: 3),
                                  PreviewBadge(
                                      isPlaying: snapshot.isPlaying,
                                      tint: foreground.withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                            _MiniButton(
                              identifier: 'twistMusic_miniPlayerPlayPauseBtn',
                              label: snapshot.isPlaying ? strings.pauseAction : strings.playAction,
                              icon: snapshot.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 24,
                              color: foreground,
                              onPressed: loading ? null : player.controller.togglePlayPause,
                            ),
                            _MiniButton(
                              identifier: 'twistMusic_miniPlayerCloseBtn',
                              label: strings.miniPlayerClose,
                              icon: Icons.close_rounded,
                              size: 18,
                              color: foreground.withValues(alpha: 0.6),
                              onPressed: player.controller.stop,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The bar's bounds in global coordinates, for the expand transition.
Rect? _globalRect(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.identifier,
    required this.label,
    required this.icon,
    required this.size,
    required this.color,
    required this.onPressed,
  });

  final String identifier;
  final String label;
  final IconData icon;
  final double size;
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
          icon: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
