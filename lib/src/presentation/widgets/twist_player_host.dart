import 'dart:async';
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/physics.dart';

import '../../analytics/twist_analytics.dart';
import '../../theme/twist_colors.dart';
import '../../theme/twist_music_theme.dart';
import '../../twist_music_player_impl.dart';
import '../twist_player_surface.dart';
import 'full_player/full_player_body.dart';
import 'full_player/full_player_queue_sheet.dart';
import 'twist_mini_player.dart';
import 'twist_sheet_scope.dart';

/// Docks the player above the host's bottom bar and expands it in place.
///
/// One surface morphs from the 56-pt bar to the full screen on a spring: the
/// artwork flies from its 44-pt slot to the full-size slot, the bar's row
/// fades out and the full player's content fades in, the way the native
/// player expands. Sheets (queue, download prompt) render in the same layer,
/// so nothing ends up under the player. Wrap the `MaterialApp.builder` child.
class TwistPlayerHost extends StatefulWidget {
  const TwistPlayerHost({
    super.key,
    required this.child,
    this.bottomInset = 0,
    this.sideInset = 12,
    this.bottomGap = 8,
    this.visible,
    this.respectSafeArea = true,
  });

  final Widget child;

  /// Height of whatever the bar must float above (tab bar, nav bar).
  final double bottomInset;
  final double sideInset;
  final double bottomGap;

  /// Host-controlled bar visibility, e.g. false while a screen is pushed
  /// over the tab root. Null means visible whenever a track is loaded.
  final ValueListenable<bool>? visible;

  /// Adds the bottom safe-area padding to [bottomInset].
  final bool respectSafeArea;

  static const double miniPlayerHeight = 56;

  /// Space a scroll view should reserve while the bar is shown.
  static double bottomPaddingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TwistPlayerInset>()?.inset ?? 0;

  /// A context under the Navigator inside the nearest [TwistPlayerHost], or
  /// null when [context] is not inside one.
  static BuildContext? navigatorContextOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_TwistHostScope>()?.findNavigatorContext();

  @override
  State<TwistPlayerHost> createState() => _TwistPlayerHostState();
}

class _TwistPlayerHostState extends State<TwistPlayerHost>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements TwistPlayerSurface {
  late final TwistMusicPlayer _player;
  late final AnimationController _expansion = AnimationController(vsync: this);
  late final AnimationController _appear =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _artworkKey = GlobalKey();
  final List<_HostSheet> _sheets = <_HostSheet>[];
  bool _expanded = false;

  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 230, ratio: 0.88);

  @override
  bool get isExpanded => _expanded;

  @override
  void initState() {
    super.initState();
    _player = TwistMusicPlayer.instance;
    _player.attachSurface(this);
    _player.isActive.addListener(_onActiveChanged);
    _player.controller.addListener(_checkPrompt);
    WidgetsBinding.instance.addObserver(this);
    if (_player.isActive.value) _appear.value = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrompt());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.controller.removeListener(_checkPrompt);
    _player.isActive.removeListener(_onActiveChanged);
    _player.detachSurface(this);
    for (final sheet in _sheets) {
      sheet.controller.dispose();
      if (!sheet.completer.isCompleted) sheet.completer.complete(null);
    }
    _expansion.dispose();
    _appear.dispose();
    super.dispose();
  }

  void _onActiveChanged() {
    if (!mounted) return;
    if (_player.isActive.value) {
      if (_appear.value == 0) _appear.forward();
      return;
    }
    _expanded = false;
    _expansion.value = 0;
    _appear.value = 0;
    for (final sheet in List<_HostSheet>.of(_sheets)) {
      unawaited(_finishSheet(sheet, null, animate: false));
    }
    setState(() {});
  }

  /// The host presents due prompts itself: the bar's row is not built while
  /// the player is expanded, so it cannot rely on the row's listener.
  void _checkPrompt() {
    if (!mounted) return;
    final request = _player.controller.value.pendingDownloadPrompt;
    if (request == null || !_player.claimDownloadPrompt(request)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _player.presentDownloadPrompt(context, request, source: TwistAnalyticsSources.promptMini);
    });
  }

  /// Android back collapses the expanded player before the app's Navigator
  /// gets a chance to pop, when the Navigator has nothing to pop itself.
  @override
  Future<bool> didPopRoute() async {
    if (!_expanded) return false;
    unawaited(collapse());
    return true;
  }

  // TwistPlayerSurface --------------------------------------------------------

  Future<void> _animateTo(double target, {double velocity = 0}) =>
      _expansion.animateWith(SpringSimulation(
        _spring,
        _expansion.value,
        target,
        velocity,
        tolerance: const Tolerance(distance: 0.0005, velocity: 0.005),
      ));

  @override
  Future<void> expand() async {
    if (_expanded || !_player.isActive.value) return;
    setState(() => _expanded = true);
    await _animateTo(1);
  }

  @override
  Future<void> collapse() async {
    if (!_expanded) return;
    setState(() => _expanded = false);
    await _animateTo(0);
  }

  @override
  Future<T?> showSheet<T>(WidgetBuilder builder) {
    final sheet = _HostSheet(
      builder,
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
    );
    setState(() => _sheets.add(sheet));
    sheet.controller.forward();
    return sheet.completer.future.then((value) => value as T?);
  }

  Future<void> _finishSheet(_HostSheet sheet, Object? result, {bool animate = true}) async {
    if (sheet.closing) return;
    sheet.closing = true;
    if (animate && mounted) await sheet.controller.reverse();
    if (mounted) setState(() => _sheets.remove(sheet));
    sheet.controller.dispose();
    if (!sheet.completer.isCompleted) sheet.completer.complete(result);
  }

  // Gestures ------------------------------------------------------------------

  void _onDragUpdate(DragUpdateDetails details, double height) {
    if (!_expanded) return;
    _expansion.value = (_expansion.value - (details.primaryDelta ?? 0) / height).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details, double height) {
    if (!_expanded) return;
    final vy = details.velocity.pixelsPerSecond.dy;
    final shouldCollapse = vy > 700 || (_expansion.value < 0.55 && vy > -700);
    if (shouldCollapse) {
      setState(() => _expanded = false);
      unawaited(_animateTo(0, velocity: -vy / height));
    } else {
      unawaited(_animateTo(1, velocity: -vy / height));
    }
  }

  Future<void> _openQueue() async {
    final snapshot = _player.controller.value;
    final track = snapshot.currentTrack;
    if (track != null) {
      _player.analytics.queueOpened(track, queueCount: snapshot.queue.length);
    }
    final height = MediaQuery.sizeOf(context).height;
    await showSheet<void>(
      (_) => SizedBox(
        height: height * 0.6,
        child: TwistQueueSheetBody(background: _player.artworkPalette.value.backgroundTop),
      ),
    );
  }

  // Measurement ---------------------------------------------------------------

  /// The full player's artwork slot relative to the full-size body; the body
  /// is always laid out, so this is available before the expansion starts.
  Rect? _measureArtworkTarget() {
    final art = _artworkKey.currentContext?.findRenderObject();
    final body = _bodyKey.currentContext?.findRenderObject();
    if (art is! RenderBox || body is! RenderBox) return null;
    if (!art.attached || !body.attached || !art.hasSize || !body.hasSize) return null;
    return art.localToGlobal(Offset.zero, ancestor: body) & art.size;
  }

  /// Breadth-first search below the child for the first Navigator; its
  /// Overlay's context is a valid context for pushing routes and sheets.
  BuildContext? _findNavigatorContext() {
    final root = _childKey.currentContext;
    if (root == null) return null;
    final queue = <Element>[];
    (root as Element).visitChildElements(queue.add);
    var visited = 0;
    while (queue.isNotEmpty && visited < 5000) {
      final element = queue.removeAt(0);
      visited++;
      if (element is StatefulElement && element.state is NavigatorState) {
        final overlay = (element.state as NavigatorState).overlay;
        if (overlay != null) return overlay.context;
      }
      element.visitChildElements(queue.add);
    }
    return null;
  }

  // Build ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return _TwistHostScope(
      findNavigatorContext: _findNavigatorContext,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final padding = MediaQuery.paddingOf(context);
          final safe = widget.respectSafeArea ? padding.bottom : 0.0;
          final fullRadius = padding.bottom > 0 ? 45.0 : 0.0;
          final barBottom = size.height - (widget.bottomInset + widget.bottomGap + safe);
          final barRect = Rect.fromLTWH(
            widget.sideInset,
            barBottom - TwistPlayerHost.miniPlayerHeight,
            size.width - 2 * widget.sideInset,
            TwistPlayerHost.miniPlayerHeight,
          );
          final fullRect = Offset.zero & size;
          return AnimatedBuilder(
            animation: Listenable.merge([
              player.isActive,
              player.controller,
              player.artworkPalette,
              _expansion,
              _appear,
              if (widget.visible != null) widget.visible!,
            ]),
            builder: (context, _) {
              final t = _expansion.value.clamp(0.0, 1.0);
              final hostVisible = widget.visible?.value ?? true;
              final show = player.isActive.value && (hostVisible || t > 0);
              final barShown = show && !_expanded && t == 0;
              return _TwistPlayerInset(
                inset: barShown ? TwistPlayerHost.miniPlayerHeight + widget.bottomGap : 0,
                child: Stack(
                  children: [
                    KeyedSubtree(key: _childKey, child: widget.child),
                    if (show) ..._buildOverlay(context, size, barRect, fullRect, fullRadius, t),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildOverlay(
    BuildContext context,
    Size size,
    Rect barRect,
    Rect fullRect,
    double fullRadius,
    double t,
  ) {
    final theme = TwistMusicTheme.of(context);
    final snapshot = _player.controller.value;
    final track = snapshot.currentTrack;
    final palette = _player.artworkPalette.value;
    final appear = Curves.easeOut.transform(_appear.value);

    final rect = Rect.lerp(barRect, fullRect, t)!;
    final radius = lerpDouble(TwistPlayerHost.miniPlayerHeight / 2, fullRadius, t)!;
    final miniArt = Rect.fromLTWH(barRect.left + 12, barRect.top + 6, 44, 44);
    final side = size.width - 48;
    final target = _measureArtworkTarget() ??
        Rect.fromCenter(center: fullRect.center, width: side, height: side);
    final artRect = Rect.lerp(miniArt, target, t)!;

    final miniOpacity = (1 - t / 0.25).clamp(0.0, 1.0);
    final fullOpacity = ((t - 0.25) / 0.45).clamp(0.0, 1.0);
    final surfaceOpacity = (t / 0.3).clamp(0.0, 1.0);
    final artworkUrl = track?.preferredFullArtworkUrl;

    return [
      if (t > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.35 * t)),
          ),
        ),
      Positioned.fromRect(
        rect: rect,
        child: Opacity(
          opacity: appear,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - appear)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: t == 0 ? () => _player.openFullPlayer(context, analyticsVia: 'tap') : null,
              onVerticalDragUpdate:
                  _expanded ? (details) => _onDragUpdate(details, size.height) : null,
              onVerticalDragEnd: _expanded ? (details) => _onDragEnd(details, size.height) : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1F000000),
                      blurRadius: 8 + 16 * t,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (t < 0.3)
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: ColoredBox(
                              color: theme.miniPlayerBackground ?? const Color(0xB8FFFFFF)),
                        ),
                      if (t > 0)
                        Opacity(
                          opacity: surfaceOpacity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: TwistColors.darkNavy,
                              gradient: fullPlayerGradient(palette),
                            ),
                          ),
                        ),
                      OverflowBox(
                        alignment: Alignment.topCenter,
                        minWidth: size.width,
                        maxWidth: size.width,
                        minHeight: size.height,
                        maxHeight: size.height,
                        child: Opacity(
                          opacity: fullOpacity,
                          child: IgnorePointer(
                            ignoring: t < 0.99,
                            child: KeyedSubtree(
                              key: _bodyKey,
                              child: SizedBox(
                                width: size.width,
                                height: size.height,
                                child: TwistFullPlayerBody(
                                  paintBackground: false,
                                  hideArtwork: true,
                                  artworkKey: _artworkKey,
                                  onCollapse: collapse,
                                  onOpenQueue: _openQueue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (t < 0.25)
                        Positioned(
                          top: 0,
                          left: 0,
                          width: barRect.width,
                          height: TwistPlayerHost.miniPlayerHeight,
                          child: Opacity(
                            opacity: miniOpacity,
                            child: IgnorePointer(
                              ignoring: t > 0,
                              child: TwistMiniPlayerContent(snapshot: snapshot, showArtwork: false),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned.fromRect(
        rect: artRect,
        child: IgnorePointer(
          child: Opacity(
            opacity: appear,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: artworkUrl == null
                  ? ColoredBox(
                      color: theme.artworkPlaceholder ?? TwistColors.artworkPlaceholder,
                      child: Icon(Iconsax.musicnote,
                          size: artRect.width * 0.4, color: Colors.black.withValues(alpha: 0.25)),
                    )
                  : CachedNetworkImage(
                      imageUrl: artworkUrl.toString(),
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (_, __) => ColoredBox(
                          color: theme.artworkPlaceholder ?? TwistColors.artworkPlaceholder),
                      errorWidget: (_, __, ___) => ColoredBox(
                          color: theme.artworkPlaceholder ?? TwistColors.artworkPlaceholder),
                    ),
            ),
          ),
        ),
      ),
      for (final sheet in _sheets) _buildSheet(sheet),
    ];
  }

  Widget _buildSheet(_HostSheet sheet) {
    final animation = CurvedAnimation(
      parent: sheet.controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _finishSheet(sheet, null),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.45 * animation.value)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FractionalTranslation(
                translation: Offset(0, 1 - animation.value),
                child: TwistSheetScope(
                  close: (result) => _finishSheet(sheet, result),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Builder(builder: sheet.builder),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostSheet {
  _HostSheet(this.builder, this.controller);

  final WidgetBuilder builder;
  final AnimationController controller;
  final Completer<Object?> completer = Completer<Object?>();
  bool closing = false;
}

class _TwistHostScope extends InheritedWidget {
  const _TwistHostScope({required this.findNavigatorContext, required super.child});

  final BuildContext? Function() findNavigatorContext;

  @override
  bool updateShouldNotify(_TwistHostScope oldWidget) => false;
}

class _TwistPlayerInset extends InheritedWidget {
  const _TwistPlayerInset({required this.inset, required super.child});

  final double inset;

  @override
  bool updateShouldNotify(_TwistPlayerInset oldWidget) => oldWidget.inset != inset;
}
