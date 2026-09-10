import 'package:flutter/material.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';
import '../../../utils/track_time_format.dart';

/// Seekable progress bar. Shows the drag position live, seeks on release and
/// holds the dragged position until the engine catches up.
class FullPlayerScrubBar extends StatefulWidget {
  const FullPlayerScrubBar({
    super.key,
    required this.progressSeconds,
    required this.durationSeconds,
    required this.onSeek,
  });

  final double progressSeconds;
  final double durationSeconds;
  final ValueChanged<double> onSeek;

  @override
  State<FullPlayerScrubBar> createState() => _FullPlayerScrubBarState();
}

class _FullPlayerScrubBarState extends State<FullPlayerScrubBar> {
  double? _dragFraction;
  double? _pendingFraction;

  double get _displayedFraction {
    final duration = widget.durationSeconds <= 0 ? 1.0 : widget.durationSeconds;
    final live = (widget.progressSeconds / duration).clamp(0.0, 1.0);
    final pending = _pendingFraction;
    if (pending != null) {
      if ((live - pending).abs() * duration <= 1.0) {
        _pendingFraction = null;
        return live;
      }
      return pending;
    }
    return _dragFraction ?? live;
  }

  double _fractionFor(Offset localPosition, double width) =>
      (localPosition.dx / width).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    final fraction = _displayedFraction;
    final dragging = _dragFraction != null;
    const labelStyle = TextStyle(
      fontSize: 11,
      color: TwistColors.onDarkMuted,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'twistMusic_scrubBar',
            label: strings.playbackPosition,
            excludeSemantics: true,
            container: true,
            slider: true,
            value: formatTrackTime(fraction * widget.durationSeconds),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) =>
                      setState(() => _dragFraction = _fractionFor(d.localPosition, width)),
                  onHorizontalDragUpdate: (d) =>
                      setState(() => _dragFraction = _fractionFor(d.localPosition, width)),
                  onHorizontalDragEnd: (_) => _commit(),
                  onHorizontalDragCancel: () => setState(() => _dragFraction = null),
                  onTapDown: (d) =>
                      setState(() => _dragFraction = _fractionFor(d.localPosition, width)),
                  onTapUp: (_) => _commit(),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: TwistColors.onDarkFaint,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: TwistColors.onDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (width * fraction - (dragging ? 9 : 4)).clamp(0.0, width - 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: dragging ? 18 : 8,
                            height: dragging ? 18 : 8,
                            decoration: BoxDecoration(
                              color: TwistColors.onDark,
                              shape: BoxShape.circle,
                              boxShadow: dragging
                                  ? const [BoxShadow(color: Color(0x66000000), blurRadius: 6)]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatTrackTime(fraction * widget.durationSeconds), style: labelStyle),
              Text(formatTrackTime(widget.durationSeconds), style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }

  void _commit() {
    final fraction = _dragFraction;
    if (fraction == null) return;
    setState(() {
      _dragFraction = null;
      _pendingFraction = fraction;
    });
    widget.onSeek(fraction * widget.durationSeconds);
  }
}
