import 'package:flutter/material.dart';

import '../../../l10n/twist_strings.dart';
import '../../../theme/twist_colors.dart';

/// Persistent "listen to the full song" card with a Get-app button.
class FullPlayerPromoCard extends StatelessWidget {
  const FullPlayerPromoCard({super.key, required this.onGetApp, this.logo});

  final VoidCallback onGetApp;
  final ImageProvider? logo;

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TwistColors.promoCardFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (logo != null) ...[
              ExcludeSemantics(
                child: SizedBox(
                  width: 60,
                  height: 24,
                  child: Image(image: logo!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                strings.promoTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: TwistColors.onDark),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              identifier: 'twistMusic_promoGetAppBtn',
              label: strings.promoCta,
              excludeSemantics: true,
              container: true,
              button: true,
              child: GestureDetector(
                onTap: onGetApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TwistColors.promoCtaFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    strings.promoCta,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: TwistColors.onDark),
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
