import 'package:flutter/material.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';

/// Collapse chevron and the "playing from" label.
class FullPlayerTopBar extends StatelessWidget {
  const FullPlayerTopBar({super.key, required this.onCollapse});

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Semantics(
              identifier: 'twistMusic_fullPlayerCollapseBtn',
              label: strings.fullPlayerCollapse,
              excludeSemantics: true,
              container: true,
              button: true,
              child: SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onCollapse,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 24, color: TwistColors.onDark),
                ),
              ),
            ),
            Expanded(
              child: Text(
                strings.fullPlayerSectionLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0x80FFFFFF),
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
