import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../twist_music_player_impl.dart';
import 'twist_mini_player.dart';

/// Optional convenience: docks [TwistMiniPlayer] above the host's bottom bar
/// and fades it in when playback starts. Wrap the `MaterialApp.builder`
/// child, or any subtree the bar should float over.
///
/// The bar is painted above everything inside [child], including modal
/// routes, so it hides itself while the package's own full player or sheets
/// are open. Because it sits above the Navigator, it locates the Navigator
/// inside [child] on demand for opening the full player and the prompt.
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

  /// Host-controlled visibility, e.g. false while a screen is pushed over
  /// the tab root. Null means visible whenever a track is loaded.
  final ValueListenable<bool>? visible;

  /// Adds the bottom safe-area padding to [bottomInset].
  final bool respectSafeArea;

  static const double miniPlayerHeight = 56;

  /// Space a scroll view should reserve while the bar is shown.
  static double bottomPaddingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TwistPlayerInset>()?.inset ?? 0;

  /// A context under the Navigator inside the nearest [TwistPlayerHost], or
  /// null when [context] is not inside one.
  static BuildContext? navigatorContextOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<_TwistHostScope>()
      ?.findNavigatorContext();

  @override
  State<TwistPlayerHost> createState() => _TwistPlayerHostState();
}

class _TwistPlayerHostState extends State<TwistPlayerHost> {
  final GlobalKey _childKey = GlobalKey();

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

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    final listenable = Listenable.merge([
      player.isActive,
      player.isPackageRouteOpen,
      if (widget.visible != null) widget.visible!,
    ]);
    return _TwistHostScope(
      findNavigatorContext: _findNavigatorContext,
      child: AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final shown = player.isActive.value &&
              !player.isPackageRouteOpen.value &&
              (widget.visible?.value ?? true);
          final safe = widget.respectSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;
          return _TwistPlayerInset(
            inset: shown ? TwistPlayerHost.miniPlayerHeight + widget.bottomGap : 0,
            child: Stack(
              children: [
                KeyedSubtree(key: _childKey, child: widget.child),
                Positioned(
                  left: widget.sideInset,
                  right: widget.sideInset,
                  bottom: widget.bottomInset + widget.bottomGap + safe,
                  child: _AppearAnimation(
                    shown: shown,
                    child: const TwistMiniPlayer(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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

/// 280 ms fade and 24-pt rise on appearance; 150 ms fade on hide so the bar
/// dissolves while the full player grows out of it.
class _AppearAnimation extends StatefulWidget {
  const _AppearAnimation({required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  State<_AppearAnimation> createState() => _AppearAnimationState();
}

class _AppearAnimationState extends State<_AppearAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: widget.shown ? 1 : 0,
  );

  @override
  void didUpdateWidget(_AppearAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shown && !oldWidget.shown) {
      _controller.forward(from: 0);
    } else if (!widget.shown && oldWidget.shown) {
      _controller.animateBack(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.shown,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, widget.shown ? 24 * (1 - t) : 0),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
