import 'dart:async';

import 'package:flutter/material.dart';

/// Centered cards with peeking neighbours, snap-to-center paging, side cards
/// scaled and faded, and a periodic auto-advance paused while touched.
class PeekCarousel extends StatefulWidget {
  const PeekCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cardWidth = 248,
    this.spacing = 16,
    this.sideScale = 0.90,
    this.sideOpacity = 0.45,
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

  @override
  State<PeekCarousel> createState() => _PeekCarouselState();
}

class _PeekCarouselState extends State<PeekCarousel> {
  PageController? _controller;
  double _fraction = 1;
  Timer? _timer;

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
    if (interval == null || widget.itemCount <= 1) return;
    _timer = Timer.periodic(interval, (_) => _advance());
  }

  void _advance() {
    final controller = _controller;
    if (controller == null || !controller.hasClients || !mounted) return;
    final current = controller.page?.round() ?? 0;
    final next = (current + 1) % widget.itemCount;
    if (next == 0 && widget.itemCount > 1) {
      controller.animateToPage(0,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    } else {
      controller.animateToPage(next,
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  PageController _controllerFor(double viewportWidth) {
    final fraction =
        ((widget.cardWidth + widget.spacing) / viewportWidth).clamp(0.2, 1.0);
    if (_controller == null || fraction != _fraction) {
      final page = _controller?.hasClients == true ? (_controller!.page ?? 0) : 0.0;
      _controller?.dispose();
      _fraction = fraction;
      _controller =
          PageController(viewportFraction: fraction, initialPage: page.round());
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
            itemCount: widget.itemCount,
            clipBehavior: Clip.none,
            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double delta = 0;
                  if (controller.hasClients && controller.position.haveDimensions) {
                    delta = ((controller.page ?? controller.initialPage.toDouble()) - index)
                        .abs()
                        .clamp(0.0, 1.0);
                  }
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
                  child: widget.itemBuilder(context, index),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
