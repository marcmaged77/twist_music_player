import 'package:flutter/material.dart';

import '../../l10n/twist_strings.dart';
import '../../theme/twist_colors.dart';
import '../../theme/twist_music_theme.dart';
import '../../twist_music_player_impl.dart';
import 'twist_sheet_scope.dart';

/// Modal "download Twist" sheet for hosts without a [TwistPlayerHost].
/// Resolves to true for Download, false for "Not now", null when dismissed.
Future<bool?> showTwistDownloadPrompt(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: TwistColors.darkNavy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const TwistDownloadPromptBody(),
  );
}

/// Sheet content: logo, headline, subtitle, Download and Not now. Closes
/// itself through [TwistSheetScope] with a bool result.
class TwistDownloadPromptBody extends StatelessWidget {
  const TwistDownloadPromptBody({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = twistStrings(context);
    final accent = TwistMusicTheme.of(context).promptAccent ?? const Color(0xFF2D5BFF);
    final logo = TwistMusicPlayer.instance.config.branding?.promoLogo;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logo != null) ...[
              ExcludeSemantics(child: Image(image: logo, height: 48, fit: BoxFit.contain)),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                strings.downloadPromptTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: TwistColors.onDark),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                strings.downloadPromptSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: TwistColors.onDarkMuted),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(
                identifier: 'twistMusic_promptDownloadBtn',
                label: strings.downloadPromptCta,
                excludeSemantics: true,
                container: true,
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: TwistColors.onDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => TwistSheetScope.closeWith(context, true),
                    child: Text(strings.downloadPromptCta),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              identifier: 'twistMusic_promptNotNowBtn',
              label: strings.downloadPromptDismiss,
              excludeSemantics: true,
              container: true,
              button: true,
              child: TextButton(
                onPressed: () => TwistSheetScope.closeWith(context, false),
                child: Text(
                  strings.downloadPromptDismiss,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: Color(0x80FFFFFF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
