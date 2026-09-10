import 'package:flutter/material.dart';

import '../../../data/models/twist_track.dart';
import '../../../data/playback/twist_playback_snapshot.dart';
import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../../../twist_music_player_impl.dart';
import '../equalizer_bars.dart';
import '../twist_artwork.dart';

/// "Up Next" entry point; hidden while the queue is empty.
class FullPlayerQueueButton extends StatelessWidget {
  const FullPlayerQueueButton({super.key, required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final strings = twistStrings(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        identifier: 'twistMusic_upNextBtn',
        label: strings.fullPlayerUpNext,
        excludeSemantics: true,
        container: true,
        button: true,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: TwistColors.onDark,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
          label: Text(strings.fullPlayerUpNext,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Half-to-full sheet listing the whole lane; the current row is highlighted.
/// Stays open after a pick, as in the native player.
Future<void> showTwistQueueSheet(BuildContext context, {required Color background}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Directionality(
      textDirection: TextDirection.ltr,
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _QueueSheetBody(
          background: background,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class _QueueSheetBody extends StatelessWidget {
  const _QueueSheetBody({required this.background, required this.scrollController});

  final Color background;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ValueListenableBuilder<TwistPlaybackSnapshot>(
        valueListenable: player.controller,
        builder: (context, snapshot, _) {
          final current = snapshot.currentTrack;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.laneTitle ?? twistStrings(context).swimlaneTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: TwistColors.onDark),
                          ),
                          if (snapshot.laneSubTitle != null)
                            Text(
                              snapshot.laneSubTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: Color(0x80FFFFFF)),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0x99FFFFFF)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x1AFFFFFF)),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: snapshot.queue.length,
                  itemBuilder: (context, index) {
                    final track = snapshot.queue[index];
                    final isCurrent = track.id == current?.id;
                    return _QueueRow(
                      track: track,
                      isCurrent: isCurrent,
                      isPlaying: isCurrent && snapshot.isPlaying,
                      onTap: () {
                        if (current != null) {
                          player.analytics.queueTrackSelected(
                              from: current, to: track, position: index + 1);
                        }
                        player.controller.selectFromQueue(track);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.track,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  final TwistTrack track;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'twistMusic_queueTrack_${track.id}',
      label: '${track.title} ${track.artistName}',
      excludeSemantics: true,
      container: true,
      button: true,
      selected: isCurrent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: isCurrent ? const Color(0x0FFFFFFF) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              TwistArtwork(
                url: track.preferredCompactArtworkUrl,
                size: 56,
                radius: 8,
                placeholderColor: TwistColors.artworkPlaceholderDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                          color: TwistColors.onDark,
                        )),
                    const SizedBox(height: 3),
                    Text(track.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Color(0x80FFFFFF))),
                  ],
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Center(
                    child: EqualizerBars(
                        barWidth: 3, maxHeight: 16, minHeight: 4, animate: isPlaying),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
