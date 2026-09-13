import 'dart:async';

import 'package:flutter/material.dart';

/// Centered cards with peeking neighbours, snap-to-center paging, side cards
/// scaled down, and a periodic auto-advance paused while touched. The lane
/// wraps around in both directions, so scrolling never hits an end.
class PeekCarousel extends StatefulWidget {
  const PeekCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardWidth = 248,
    this.spacing = 2,
    this.sideScale = 0.90,
    this.sideOpacity = 1.0,
    this.autoScrollInterval = const Duration(seconds: 4),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double cardWidth;
  final double spacing;
  final double sideScale;
  final double sideOpacity;

  /// Null disables auto-advance.
  final Duration? autoScrollInterval;

  /// Pages start this many loops in so the lane can be swiped backwards too.
  static const int loops = 1000;

  @override
  State<PeekCarousel> createState() => _PeekCarouselState();
}

class _PeekCarouselState extends State<PeekCarousel> {
  PageController? _controller;
  double _fraction = 1;
  int _itemCount = 0;
  Timer? _timer;

  bool get _wraps => widget.itemCount > 1;

  @override
  void initState() {
    super.initState();
    _scheduleAutoScroll();
  }

  @override
  void didUpdateWidget(PeekCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.autoScrollInterval != widget.autoScrollInterval) {
      _scheduleAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll() {
    _timer?.cancel();
    final interval = widget.autoScrollInterval;
    if (interval == null || !_wraps) return;
    _timer = Timer.periodic(interval, (_) => _advance());
  }

  void _advance() {
    final controller = _controller;
    if (controller == null || !controller.hasClients || !mounted) return;
    final current = controller.page?.round() ?? controller.initialPage;
    controller.animateToPage(current + 1,
        duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
  }

  PageController _controllerFor(double viewportWidth) {
    final fraction = ((widget.cardWidth + widget.spacing) / viewportWidth).clamp(0.2, 1.0);
    if (_controller == null || fraction != _fraction || _itemCount != widget.itemCount) {
      final base = _wraps ? widget.itemCount * PeekCarousel.loops : 0;
      final page = _controller?.hasClients == true ? (_controller!.page ?? base) : base.toDouble();
      final keep = _itemCount == widget.itemCount ? page.round() : base;
      _controller?.dispose();
      _fraction = fraction;
      _itemCount = widget.itemCount;
      _controller = PageController(viewportFraction: fraction, initialPage: keep);
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final controller = _controllerFor(constraints.maxWidth);
        return Listener(
          onPointerDown: (_) => _timer?.cancel(),
          onPointerUp: (_) => _scheduleAutoScroll(),
          onPointerCancel: (_) => _scheduleAutoScroll(),
          child: PageView.builder(
            controller: controller,
            itemCount: _wraps ? null : widget.itemCount,
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
            itemBuilder: (context, index) {
              final item = _wraps ? index % widget.itemCount : index;
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  // Before the first layout there is no page yet; the initial
                  // page keeps the neighbours scaled from the very first frame.
                  final page = controller.hasClients && controller.position.haveDimensions
                      ? controller.page ?? controller.initialPage.toDouble()
                      : controller.initialPage.toDouble();
                  final delta = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (1 - widget.sideScale) * delta;
                  final opacity = 1 - (1 - widget.sideOpacity) * delta;
                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: SizedBox(
                  width: widget.cardWidth,
                  child: widget.itemBuilder(context, item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
