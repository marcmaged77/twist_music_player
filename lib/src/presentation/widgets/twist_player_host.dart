import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../twist_music_player_impl.dart';
import 'twist_mini_player.dart';

/// Optional convenience: docks [TwistMiniPlayer] above the host's bottom bar
/// and fades it in when playback starts. Wrap the `MaterialApp.builder`
/// child, or any subtree the bar should float over.
class TwistPlayerHost extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final player = TwistMusicPlayer.instance;
    final listenable = visible == null
        ? player.isActive
        : Listenable.merge([player.isActive, visible!]);
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final shown = player.isActive.value && (visible?.value ?? true);
        final safe = respectSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;
        return _TwistPlayerInset(
          inset: shown ? miniPlayerHeight + bottomGap : 0,
          child: Stack(
            children: [
              child,
              Positioned(
                left: sideInset,
                right: sideInset,
                bottom: bottomInset + bottomGap + safe,
                child: _AppearAnimation(
                  shown: shown,
                  child: const TwistMiniPlayer(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TwistPlayerInset extends InheritedWidget {
  const _TwistPlayerInset({required this.inset, required super.child});

  final double inset;

  @override
  bool updateShouldNotify(_TwistPlayerInset oldWidget) => oldWidget.inset != inset;
}

/// 280 ms fade and 24-pt rise on appearance; instant hide.
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
      _controller.value = 0;
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
            opacity: widget.shown ? t : 0,
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
