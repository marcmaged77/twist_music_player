import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../analytics/twist_analytics.dart';
import '../../data/models/twist_track.dart';
import '../../data/playback/twist_playback_snapshot.dart';
import '../../data/playback/twist_playback_status.dart';
import '../../theme/twist_colors.dart';
import '../../twist_music_player_impl.dart';
import '../../utils/artwork_palette.dart';
import '../widgets/full_player/full_player_controls.dart';
import '../widgets/full_player/full_player_promo_card.dart';
import '../widgets/full_player/full_player_queue_sheet.dart';
import '../widgets/full_player/full_player_scrub_bar.dart';
import '../widgets/full_player/full_player_top_bar.dart';
import '../widgets/preview_badge.dart';
import '../widgets/twist_artwork.dart';

/// Route hosting [TwistFullPlayerScreen]. Pops with a
/// [TwistDownloadPromptRequest] when a prompt becomes due while open.
///
/// With [expandFrom] (the mini player's rectangle) the page grows out of the
/// bar and shrinks back into it on close, the way the native player expands.
/// Without it the page slides up from the bottom.
class TwistFullPlayerRoute extends PageRouteBuilder<Object?> {
  TwistFullPlayerRoute({Rect? expandFrom})
      : super(
          opaque: false,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, __, ___) => const TwistFullPlayerScreen(),
          transitionsBuilder: (context, animation, _, child) {
            if (expandFrom == null) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              );
            }
            return _ExpandFromRectTransition(
              animation: animation,
              origin: expandFrom,
              child: child,
            );
          },
        );
}

/// Container transform: the full-size page is laid out at its final size and
/// revealed through a rectangle that grows from [origin] to the screen while
/// the corner radius relaxes from the mini player's capsule to square.
class _ExpandFromRectTransition extends StatelessWidget {
  const _ExpandFromRectTransition({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final Rect origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final full = Offset.zero & size;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        final rect = Rect.lerp(origin, full, t)!;
        final radius = lerpDouble(origin.height / 2, 0, t)!;
        final contentOpacity = ((t - 0.15) / 0.45).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: size.width,
                  maxWidth: size.width,
                  minHeight: size.height,
                  maxHeight: size.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: TwistColors.darkNavy),
                      Opacity(opacity: contentOpacity, child: child),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The full player: promo card, artwork, scrub bar, controls and Up Next.
/// Dark, artwork-tinted and forced left-to-right, as in the native apps.
class TwistFullPlayerScreen extends StatefulWidget {
  const TwistFullPlayerScreen({super.key});

  @override
  State<TwistFullPlayerScreen> createState() => _TwistFullPlayerScreenState();
}

class _TwistFullPlayerScreenState extends State<TwistFullPlayerScreen> {
  static final ArtworkPaletteResolver _paletteResolver = ArtworkPaletteResolver();

  late final TwistMusicPlayer _player;

  ArtworkPalette _palette = ArtworkPalette.fallback;
  Uri? _paletteUrl;
  double _dragOffset = 0;
  bool _dragging = false;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _player = TwistMusicPlayer.instance;
    _player.controller.addListener(_onSnapshot);
    _updatePalette(_player.controller.value.currentTrack);
  }

  @override
  void dispose() {
    _player.controller.removeListener(_onSnapshot);
    super.dispose();
  }

  void _onSnapshot() {
    final snapshot = _player.controller.value;
    if (!snapshot.isActive) {
      _pop(null);
      return;
    }
    final prompt = snapshot.pendingDownloadPrompt;
    if (prompt != null && _player.claimDownloadPrompt(prompt)) {
      _pop(prompt);
      return;
    }
    _updatePalette(snapshot.currentTrack);
  }

  /// Pops when hosted as a pushed route; a host that mounts the screen as a
  /// root (tab, home) simply keeps it.
  void _pop(Object? result) {
    if (_popped || !mounted) return;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;
    _popped = true;
    navigator.pop(result);
  }

  Future<void> _updatePalette(TwistTrack? track) async {
    final url = track?.preferredFullArtworkUrl;
    if (url == null || url == _paletteUrl) return;
    _paletteUrl = url;
    final palette = await _paletteResolver.resolve(CachedNetworkImageProvider(url.toString()));
    if (!mounted || _paletteUrl != url) return;
    setState(() => _palette = palette);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final height = MediaQuery.sizeOf(context).height;
    final projected = _dragOffset + details.velocity.pixelsPerSecond.dy * 0.2;
    if (projected > height * 0.5) {
      _pop(null);
      return;
    }
    setState(() {
      _dragging = false;
      _dragOffset = 0;
    });
  }

  Future<void> _openQueue(TwistPlaybackSnapshot snapshot) async {
    final track = snapshot.currentTrack;
    if (track != null) {
      _player.analytics.queueOpened(track, queueCount: snapshot.queue.length);
    }
    await showTwistQueueSheet(context, background: _palette.backgroundTop);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _player.controller;
    final branding = _player.config.branding;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<TwistPlaybackSnapshot>(
        valueListenable: controller,
        builder: (context, snapshot, _) {
          final track = snapshot.currentTrack;
          return AnimatedContainer(
            duration: _dragging ? Duration.zero : const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            child: GestureDetector(
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_dragOffset > 0 ? 45 : 0)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: TwistColors.darkNavy,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.alphaBlend(const Color(0x26000000), _palette.backgroundTop),
                        Color.alphaBlend(const Color(0x26000000), _palette.backgroundBottom),
                      ],
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SafeArea(
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
                          FullPlayerTopBar(onCollapse: () => _pop(null)),
                          const SizedBox(height: 8),
                          FullPlayerPromoCard(
                            logo: branding?.promoLogo,
                            onGetApp: () => _player.openDownloadLink(
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
                                    return TwistArtwork(
                                      url: track?.preferredFullArtworkUrl,
                                      size: side,
                                      radius: 10,
                                      placeholderColor: TwistColors.artworkPlaceholderDark,
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
                                  style: const TextStyle(
                                      fontSize: 16, color: TwistColors.onDarkMuted),
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
                          PreviewBadge(
                              isPlaying: snapshot.isPlaying, tint: const Color(0xB3FFFFFF)),
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
                          FullPlayerQueueButton(
                            visible: snapshot.hasQueue,
                            onPressed: () => _openQueue(snapshot),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
