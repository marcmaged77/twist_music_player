import 'package:flutter/material.dart';

import '../../analytics/twist_analytics.dart';
import '../../data/models/twist_track.dart';
import '../../l10n/twist_strings.dart';
import '../../theme/twist_music_theme.dart';
import '../../twist_music_player_impl.dart';
import '../controllers/twist_lane_controller.dart';
import 'swimlane/banner_band.dart';
import 'swimlane/peek_carousel.dart';
import 'swimlane/swimlane_banner.dart';
import 'swimlane/swimlane_header.dart';
import 'swimlane/swimlane_skeleton.dart';
import 'swimlane/track_card.dart';
import 'twist_prompt_listener.dart';

/// How the lane's header is drawn.
enum TwistSwimlaneStyle {
  /// Logo, title and a promo chip on the host's background.
  plain,

  /// A gradient band with the logo, title, offer text and a download pill;
  /// the cards overlap the band's bottom edge.
  banner,
}

/// The promotional lane: a header and an endless peek carousel of artwork
/// cards.
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
    this.cardWidth,
    this.backgroundColor,
    this.style = TwistSwimlaneStyle.plain,
    this.autoScrollInterval = const Duration(seconds: 4),
    this.padding = const EdgeInsets.only(top: 16, bottom: 20),
  });

  /// Fires with true once at least one track is loaded, false otherwise.
  final ValueChanged<bool>? onContentAvailabilityChanged;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;

  /// Square card side. Null sizes it from the width, so the neighbours peek.
  final double? cardWidth;

  /// Fill behind the lane. Null uses [TwistMusicTheme.laneBackground], transparent by default.
  final Color? backgroundColor;

  final TwistSwimlaneStyle style;

  /// Null disables auto-advance.
  final Duration? autoScrollInterval;
  final EdgeInsetsGeometry padding;

  /// Card side for a lane [width] pixels wide: 60 % of it, within bounds.
  static double cardSizeFor(double width) => (width * 0.6).clamp(200.0, 300.0);

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
                _band(
                  context,
                  LayoutBuilder(
                    builder: (context, constraints) => SwimlaneSkeleton(
                        banner: widget.style == TwistSwimlaneStyle.banner,
                        cardWidth: widget.cardWidth ??
                            TwistMusicSwimlane.cardSizeFor(constraints.maxWidth)),
                  ),
                );
          case TwistLaneState.empty:
            return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
          case TwistLaneState.loaded:
            return _band(context, _buildLane(context));
        }
      },
    );
  }

  Widget _band(BuildContext context, Widget child) {
    final color = widget.backgroundColor ?? TwistMusicTheme.of(context).laneBackground;
    final padded = Padding(padding: widget.padding, child: child);
    return color == null ? padded : ColoredBox(color: color, child: padded);
  }

  Widget _buildLane(BuildContext context) {
    final strings = twistStrings(context);
    final lane = _lane.lane;
    final snapshot = _player.controller.value;
    final playingId = snapshot.isPlaying ? snapshot.currentTrack?.id : null;
    final branding = _player.config.branding;
    final title = lane.title ?? strings.swimlaneTitle;
    final subtitle = lane.subTitle ?? strings.swimlaneSubtitle;
    void openDownload() => _player.openDownloadLink(source: TwistAnalyticsSources.swimlaneHeader);
    return TwistPromptListener(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = widget.cardWidth ?? TwistMusicSwimlane.cardSizeFor(constraints.maxWidth);
          final carousel = SizedBox(
            height: size,
            child: PeekCarousel(
              itemCount: lane.tracks.length,
              cardWidth: size,
              autoScrollInterval: widget.autoScrollInterval,
              itemBuilder: (context, index) {
                final track = lane.tracks[index];
                return TrackCard(
                  track: track,
                  size: size,
                  isPlaying: playingId == track.id,
                  onTap: () => _onTap(track),
                );
              },
            ),
          );
          switch (widget.style) {
            case TwistSwimlaneStyle.plain:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwimlaneHeader(
                    title: title,
                    subtitle: subtitle,
                    logo: branding?.headerLogo,
                    onPromoTap: openDownload,
                  ),
                  const SizedBox(height: 14),
                  carousel,
                ],
              );
            case TwistSwimlaneStyle.banner:
              final theme = TwistMusicTheme.of(context);
              // The rounded band sits behind the header and the top 40 % of the
              // cards; the carousel itself runs edge to edge.
              // Clip.none lets the card shadows spill below the lane.
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 0,
                    bottom: size * 0.6,
                    child: BannerBand(gradient: theme.bannerGradient),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwimlaneBanner(
                        title: title,
                        subtitle: subtitle,
                        ctaLabel: strings.downloadPromptCta,
                        logo: branding?.promoLogo ?? branding?.headerLogo,
                        onDownload: openDownload,
                        padding: const EdgeInsets.fromLTRB(36, 22, 36, 0),
                      ),
                      const SizedBox(height: 20),
                      carousel,
                    ],
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}
