import 'package:flutter/widgets.dart';

import 'twist_music_localizations.dart';
import 'twist_music_localizations_en.dart';

/// Resolves the package strings, falling back to English when the host has
/// not registered [TwistMusicLocalizations.delegate].
TwistMusicLocalizations twistStrings(BuildContext context) {
  return Localizations.of<TwistMusicLocalizations>(
          context, TwistMusicLocalizations) ??
      TwistMusicLocalizationsEn();
}
