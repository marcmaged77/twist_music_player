import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/twist_colors.dart';

/// An endless fan of cards: the centre card upright and on top, the
/// neighbours tucked under it, smaller, tilted outwards and dimmed. Swipes,
/// snapping and the auto-advance drive a hidden [PageView]; the cards are
/// painted from its page value, farthest first, so the centre one always
/// draws last. Taps are resolved against the painted cards, nearest first.
class CoverflowCarousel extends StatefulWidget {
  const CoverflowCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.cardWidth,
    required this.cardHeight,
    this.onItemTap,
    this.step = 0.62,
    this.sideScale = 0.72,
    this.sideAngle = 7,
    this.sideDim = 0.5,
    this.autoScrollInterval = const Duration(seconds: 4),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double cardWidth;
  final double cardHeight;
  final ValueChanged<int>? onItemTap;

  /// Distance between neighbouring card centres, as a fraction of [cardWidth].
  final double step;

  /// Scale, tilt in degrees (away from the centre) and strength of the white
  /// veil over a card one step from the centre. The veil dims the card while
  /// keeping it opaque.
  final double sideScale;
  final double sideAngle;
  final double sideDim;

  /// Null disables auto-advance.
  final Duration? autoScrollInterval;

  /// Pages start this many loops in so the lane can be swiped backwards too.
  static const int loops = 1000;

  @override
  State<CoverflowCarousel> createState() => _CoverflowCarouselState();
}

class _CoverflowCarouselState extends State<CoverflowCarousel> {
  PageController? _controller;
  double _viewportWidth = 0;
  int _itemCount = 0;
  Timer? _timer;

  bool get _wraps => widget.itemCount > 1;

  @override
  void initState() {
    super.initState();
    _scheduleAutoScroll();
  }

  @override
  void didUpdateWidget(CoverflowCarousel oldWidget) {
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

  // The page index runs in the thousands, so a page-controller swap must not
  // let the PageView absorb the old pixel offset: a hair's difference in the
  // viewport fraction would then shift the fan by whole pages. The controller
  // is only replaced on a real width change and the PageView is keyed to it.
  PageController _controllerFor(double viewportWidth) {
    final widthChanged = (viewportWidth - _viewportWidth).abs() > 0.5;
    if (_controller == null || widthChanged || _itemCount != widget.itemCount) {
      final base = _wraps ? widget.itemCount * CoverflowCarousel.loops : 0;
      final page = _controller?.hasClients == true ? (_controller!.page ?? base) : base.toDouble();
      final keep = _itemCount == widget.itemCount ? page.round() : base;
      final old = _controller;
      _viewportWidth = viewportWidth;
      _itemCount = widget.itemCount;
      _controller = PageController(
        viewportFraction: (widget.step * widget.cardWidth / viewportWidth).clamp(0.1, 1.0),
        initialPage: keep,
      );
      // Disposed after this frame: the outgoing PageView still listens to it.
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    }
    return _controller!;
  }

  // Before the first layout there is no page yet; the initial page keeps the
  // fan laid out from the very first frame.
  double _pageOf(PageController controller) =>
      controller.hasClients && controller.position.haveDimensions
          ? controller.page ?? controller.initialPage.toDouble()
          : controller.initialPage.toDouble();

  /// Cards further than this many steps from the centre are not drawn, so a
  /// three-track lane never shows a duplicate at rest; a card sliding in
  /// fades in over the last three quarters of a step.
  static const double _visibleRange = 1.75;

  /// The cards around [page], nearest first.
  List<_Slot> _slotsFor(double page, double width, bool rtl) {
    final slots = <_Slot>[];
    final first = page.floor() - 2;
    for (var index = first; index <= first + 5; index++) {
      if (!_wraps && (index < 0 || index >= widget.itemCount)) continue;
      final delta = (index - page) * (rtl ? -1 : 1);
      final distance = delta.abs();
      if (distance >= _visibleRange) continue;
      final t = distance.clamp(0.0, 1.0);
      slots.add(_Slot(
        index: index,
        item: _wraps ? index % widget.itemCount : index,
        distance: distance,
        center: Offset(width / 2 + delta * widget.step * widget.cardWidth, widget.cardHeight / 2),
        scale: 1 - (1 - widget.sideScale) * t,
        angle: widget.sideAngle * math.pi / 180 * delta.clamp(-1.0, 1.0),
        dim: widget.sideDim * t,
        // Only the card sliding in or out past the neighbours fades; the
        // resting neighbours stay opaque under their veil.
        opacity: distance <= 1 ? 1.0 : 1 - (distance - 1) / (_visibleRange - 1),
      ));
    }
    slots.sort((a, b) => a.distance.compareTo(b.distance));
    return slots;
  }

  /// The item under [position], honouring scale, tilt and paint order.
  int? _itemAt(Offset position, List<_Slot> slots) {
    for (final slot in slots) {
      final local = position - slot.center;
      final cos = math.cos(-slot.angle);
      final sin = math.sin(-slot.angle);
      final x = (local.dx * cos - local.dy * sin) / slot.scale;
      final y = (local.dx * sin + local.dy * cos) / slot.scale;
      if (x.abs() <= widget.cardWidth / 2 && y.abs() <= widget.cardHeight / 2) return slot.item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final controller = _controllerFor(width);
        return Listener(
          onPointerDown: (_) => _timer?.cancel(),
          onPointerUp: (_) => _scheduleAutoScroll(),
          onPointerCancel: (_) => _scheduleAutoScroll(),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final slots = _slotsFor(_pageOf(controller), width, rtl);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final slot in slots.reversed)
                          Positioned(
                            key: ValueKey(slot.index),
                            left: slot.center.dx - widget.cardWidth / 2,
                            top: slot.center.dy - widget.cardHeight / 2,
                            width: widget.cardWidth,
                            height: widget.cardHeight,
                            child: Transform.rotate(
                              angle: slot.angle,
                              child: Transform.scale(
                                scale: slot.scale,
                                child: Opacity(
                                  opacity: slot.opacity,
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      TwistColors.onDark.withValues(alpha: slot.dim),
                                      BlendMode.srcATop,
                                    ),
                                    child: widget.itemBuilder(context, slot.item),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              // A pure gesture surface: kept out of the semantics tree so that
              // accessibility-driven automation never asks it to scroll a page
              // into view (the painted tiles carry the semantics).
              ExcludeSemantics(
                child: PageView.builder(
                  key: ValueKey(controller),
                  controller: controller,
                  itemCount: _wraps ? null : widget.itemCount,
                  physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                  itemBuilder: (_, __) => const SizedBox.expand(),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) {
                  final slots = _slotsFor(_pageOf(controller), width, rtl);
                  final item = _itemAt(details.localPosition, slots);
                  if (item != null) widget.onItemTap?.call(item);
                },
                child: const SizedBox.expand(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Slot {
  const _Slot({
    required this.index,
    required this.item,
    required this.distance,
    required this.center,
    required this.scale,
    required this.angle,
    required this.dim,
    required this.opacity,
  });

  final int index;
  final int item;
  final double distance;
  final Offset center;
  final double scale;
  final double angle;
  final double dim;
  final double opacity;
}
