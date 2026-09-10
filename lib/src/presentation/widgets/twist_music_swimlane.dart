import 'package:flutter/material.dart';

import '../../data/models/twist_track.dart';
import '../../l10n/twist_strings.dart';
import '../../twist_music_player_impl.dart';
import '../controllers/twist_lane_controller.dart';
import 'swimlane/peek_carousel.dart';
import 'swimlane/swimlane_header.dart';
import 'swimlane/swimlane_skeleton.dart';
import 'swimlane/track_card.dart';
import 'twist_prompt_listener.dart';

/// The promotional lane: header, peek carousel of preview cards, badges.
///
/// Loads the shared lane on first appearance. The host decides where it goes;
/// [loadingBuilder] and [emptyBuilder] decide what shows while loading and
/// when there is nothing to show (defaults: a skeleton, nothing).
class TwistMusicSwimlane extends StatefulWidget {
  const TwistMusicSwimlane({
    super.key,
    this.onContentAvailabilityChanged,
    this.loadingBuilder,
    this.emptyBuilder,
    this.cardWidth = 248,
    this.autoScrollInterval = const Duration(seconds: 4),
    this.padding = const EdgeInsets.only(top: 12, bottom: 16),
  });

  /// Fires with true once at least one track is loaded, false otherwise.
  final ValueChanged<bool>? onContentAvailabilityChanged;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final double cardWidth;

  /// Null disables auto-advance.
  final Duration? autoScrollInterval;
  final EdgeInsetsGeometry padding;

  @override
  State<TwistMusicSwimlane> createState() => _TwistMusicSwimlaneState();
}

class _TwistMusicSwimlaneState extends State<TwistMusicSwimlane> {
  late final TwistMusicPlayer _player;
  late final TwistLaneController _lane;

  bool? _lastAvailability;

  @override
  void initState() {
    super.initState();
    _player = TwistMusicPlayer.instance;
    _lane = _player.laneController;
    _lane.addListener(_notifyAvailability);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lane.loadIfNeeded();
      _notifyAvailability();
    });
  }

  @override
  void dispose() {
    _lane.removeListener(_notifyAvailability);
    super.dispose();
  }

  void _notifyAvailability() {
    final hasContent = _lane.hasContent;
    if (_lastAvailability == hasContent) return;
    _lastAvailability = hasContent;
    widget.onContentAvailabilityChanged?.call(hasContent);
  }

  /// The engine snapshot is read directly: the controller mirrors it a
  /// microtask later, which is too late for the check right after the tap.
  Future<void> _onTap(TwistTrack track) async {
    await _lane.tapTrack(track);
    if (!mounted) return;
    final engine = _player.engine;
    if (!engine.snapshot.pendingExpansionRequest) return;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    if (!engine.snapshot.pendingExpansionRequest || !engine.snapshot.isActive) return;
    engine.acknowledgeExpansionRequest();
    await _player.openFullPlayer(context, analyticsVia: 'swimlane_first_tap');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_lane, _player.controller]),
      builder: (context, _) {
        switch (_lane.state) {
          case TwistLaneState.idle:
          case TwistLaneState.loading:
            return widget.loadingBuilder?.call(context) ??
                Padding(
                  padding: widget.padding,
                  child: SwimlaneSkeleton(cardWidth: widget.cardWidth),
                );
          case TwistLaneState.empty:
            return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
          case TwistLaneState.loaded:
            return _buildLane(context);
        }
      },
    );
  }

  Widget _buildLane(BuildContext context) {
    final strings = twistStrings(context);
    final lane = _lane.lane;
    final snapshot = _player.controller.value;
    final playingId = snapshot.isPlaying ? snapshot.currentTrack?.id : null;
    return TwistPromptListener(
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SwimlaneHeader(
              title: lane.title ?? strings.swimlaneTitle,
              subtitle: lane.subTitle ?? strings.swimlaneSubtitle,
              logo: _player.config.branding?.headerLogo,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: widget.cardWidth + 48,
              child: PeekCarousel(
                itemCount: lane.tracks.length,
                cardWidth: widget.cardWidth,
                autoScrollInterval: widget.autoScrollInterval,
                itemBuilder: (context, index) {
                  final track = lane.tracks[index];
                  return TrackCard(
                    track: track,
                    artworkSize: widget.cardWidth,
                    isPlaying: playingId == track.id,
                    onTap: () => _onTap(track),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
