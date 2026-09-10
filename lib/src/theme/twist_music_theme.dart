import 'package:flutter/material.dart';

/// Host-overridable styling for the swimlane and the mini player.
///
/// Register it as a [ThemeExtension] on the host theme to override any token;
/// otherwise [TwistMusicTheme.of] derives sensible values from
/// [ThemeData.textTheme] and [ThemeData.colorScheme].
class TwistMusicTheme extends ThemeExtension<TwistMusicTheme> {
  const TwistMusicTheme({
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.cardTitleStyle,
    this.cardArtistStyle,
    this.miniPlayerTitleStyle,
    this.miniPlayerBackground,
    this.miniPlayerForeground,
    this.artworkPlaceholder,
    this.promptAccent,
  });

  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final TextStyle? cardTitleStyle;
  final TextStyle? cardArtistStyle;
  final TextStyle? miniPlayerTitleStyle;

  /// Tint behind the mini player's blur. Null keeps the translucent default.
  final Color? miniPlayerBackground;
  final Color? miniPlayerForeground;
  final Color? artworkPlaceholder;

  /// Primary button colour of the download prompt.
  final Color? promptAccent;

  static TwistMusicTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final override = theme.extension<TwistMusicTheme>();
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final defaults = TwistMusicTheme(
      headerTitleStyle: (text.titleLarge ?? const TextStyle(fontSize: 20))
          .copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      headerSubtitleStyle: (text.bodySmall ?? const TextStyle(fontSize: 13))
          .copyWith(color: scheme.onSurfaceVariant),
      cardTitleStyle: (text.titleSmall ?? const TextStyle(fontSize: 16))
          .copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      cardArtistStyle: (text.bodySmall ?? const TextStyle(fontSize: 13))
          .copyWith(color: scheme.onSurfaceVariant),
      miniPlayerTitleStyle: (text.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      miniPlayerBackground: scheme.surface.withValues(alpha: 0.72),
      miniPlayerForeground: scheme.onSurface,
      artworkPlaceholder: scheme.surfaceContainerHighest,
      promptAccent: scheme.primary,
    );
    return override == null ? defaults : defaults.merge(override);
  }

  TwistMusicTheme merge(TwistMusicTheme other) => TwistMusicTheme(
        headerTitleStyle: other.headerTitleStyle ?? headerTitleStyle,
        headerSubtitleStyle: other.headerSubtitleStyle ?? headerSubtitleStyle,
        cardTitleStyle: other.cardTitleStyle ?? cardTitleStyle,
        cardArtistStyle: other.cardArtistStyle ?? cardArtistStyle,
        miniPlayerTitleStyle: other.miniPlayerTitleStyle ?? miniPlayerTitleStyle,
        miniPlayerBackground: other.miniPlayerBackground ?? miniPlayerBackground,
        miniPlayerForeground: other.miniPlayerForeground ?? miniPlayerForeground,
        artworkPlaceholder: other.artworkPlaceholder ?? artworkPlaceholder,
        promptAccent: other.promptAccent ?? promptAccent,
      );

  @override
  TwistMusicTheme copyWith({
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    TextStyle? cardTitleStyle,
    TextStyle? cardArtistStyle,
    TextStyle? miniPlayerTitleStyle,
    Color? miniPlayerBackground,
    Color? miniPlayerForeground,
    Color? artworkPlaceholder,
    Color? promptAccent,
  }) =>
      TwistMusicTheme(
        headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
        headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
        cardTitleStyle: cardTitleStyle ?? this.cardTitleStyle,
        cardArtistStyle: cardArtistStyle ?? this.cardArtistStyle,
        miniPlayerTitleStyle: miniPlayerTitleStyle ?? this.miniPlayerTitleStyle,
        miniPlayerBackground: miniPlayerBackground ?? this.miniPlayerBackground,
        miniPlayerForeground: miniPlayerForeground ?? this.miniPlayerForeground,
        artworkPlaceholder: artworkPlaceholder ?? this.artworkPlaceholder,
        promptAccent: promptAccent ?? this.promptAccent,
      );

  @override
  TwistMusicTheme lerp(ThemeExtension<TwistMusicTheme>? other, double t) {
    if (other is! TwistMusicTheme) return this;
    return TwistMusicTheme(
      headerTitleStyle: TextStyle.lerp(headerTitleStyle, other.headerTitleStyle, t),
      headerSubtitleStyle:
          TextStyle.lerp(headerSubtitleStyle, other.headerSubtitleStyle, t),
      cardTitleStyle: TextStyle.lerp(cardTitleStyle, other.cardTitleStyle, t),
      cardArtistStyle: TextStyle.lerp(cardArtistStyle, other.cardArtistStyle, t),
      miniPlayerTitleStyle:
          TextStyle.lerp(miniPlayerTitleStyle, other.miniPlayerTitleStyle, t),
      miniPlayerBackground:
          Color.lerp(miniPlayerBackground, other.miniPlayerBackground, t),
      miniPlayerForeground:
          Color.lerp(miniPlayerForeground, other.miniPlayerForeground, t),
      artworkPlaceholder: Color.lerp(artworkPlaceholder, other.artworkPlaceholder, t),
      promptAccent: Color.lerp(promptAccent, other.promptAccent, t),
    );
  }
}
