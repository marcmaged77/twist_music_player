import 'package:flutter/material.dart';

import 'twist_colors.dart';

/// Host-overridable styling for the swimlane and the mini player.
///
/// Register it as a [ThemeExtension] on the host theme to override any token.
/// The lane defaults to the dark Twist look on every host; the mini player
/// follows [ThemeData.colorScheme] unless overridden.
class TwistMusicTheme extends ThemeExtension<TwistMusicTheme> {
  const TwistMusicTheme({
    this.laneBackground,
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.cardTitleStyle,
    this.cardArtistStyle,
    this.miniPlayerTitleStyle,
    this.miniPlayerBackground,
    this.miniPlayerForeground,
    this.artworkPlaceholder,
    this.promptAccent,
    this.bannerGradient,
    this.coverflowCardFill,
    this.coverflowTitleStyle,
    this.coverflowArtistStyle,
    this.fontFamily,
  });

  /// Family the coverflow lane asks for by default. The package ships no font
  /// files: declare the family in the host app, or point [fontFamily] at a
  /// font another package bundles (for example 'packages/<pkg>/Lufga').
  static const String defaultFontFamily = 'Lufga';

  /// Fill behind the lane's header and carousel.
  final Color? laneBackground;
  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final TextStyle? cardTitleStyle;
  final TextStyle? cardArtistStyle;
  final TextStyle? miniPlayerTitleStyle;

  /// Tint behind the mini player's blur. Null keeps the translucent default.
  final Color? miniPlayerBackground;
  final Color? miniPlayerForeground;
  final Color? artworkPlaceholder;

  /// Accent of the download prompt button and the header promo chip.
  final Color? promptAccent;

  /// Static override of the animated brand band behind the banner header.
  final Gradient? bannerGradient;

  /// Fill of the coverflow tiles; translucent white by default.
  final Color? coverflowCardFill;

  /// Title and artist under the artwork of a coverflow tile; dark ink by default.
  final TextStyle? coverflowTitleStyle;
  final TextStyle? coverflowArtistStyle;

  /// Font family of the coverflow lane's texts; [defaultFontFamily] unless set.
  final String? fontFamily;

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
      cardTitleStyle: (text.titleLarge ?? const TextStyle(fontSize: 20))
          .copyWith(fontWeight: FontWeight.w700, color: TwistColors.onDark),
      cardArtistStyle: (text.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(color: TwistColors.onDarkSoft),
      miniPlayerTitleStyle: (text.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      miniPlayerBackground: scheme.surface.withValues(alpha: 0.72),
      miniPlayerForeground: scheme.onSurface,
      artworkPlaceholder: TwistColors.artworkPlaceholderDark,
      promptAccent: TwistColors.accent,
      coverflowCardFill: TwistColors.coverflowCardFill,
      coverflowTitleStyle: (text.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
          fontFamily: override?.fontFamily ?? defaultFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: TwistColors.inkTitle,
          height: 1.2),
      coverflowArtistStyle: (text.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
          fontFamily: override?.fontFamily ?? defaultFontFamily,
          fontWeight: FontWeight.w500,
          color: TwistColors.inkMuted,
          height: 1.2),
      fontFamily: defaultFontFamily,
    );
    return override == null ? defaults : defaults.merge(override);
  }

  TwistMusicTheme merge(TwistMusicTheme other) => TwistMusicTheme(
        laneBackground: other.laneBackground ?? laneBackground,
        headerTitleStyle: other.headerTitleStyle ?? headerTitleStyle,
        headerSubtitleStyle: other.headerSubtitleStyle ?? headerSubtitleStyle,
        cardTitleStyle: other.cardTitleStyle ?? cardTitleStyle,
        cardArtistStyle: other.cardArtistStyle ?? cardArtistStyle,
        miniPlayerTitleStyle: other.miniPlayerTitleStyle ?? miniPlayerTitleStyle,
        miniPlayerBackground: other.miniPlayerBackground ?? miniPlayerBackground,
        miniPlayerForeground: other.miniPlayerForeground ?? miniPlayerForeground,
        artworkPlaceholder: other.artworkPlaceholder ?? artworkPlaceholder,
        promptAccent: other.promptAccent ?? promptAccent,
        bannerGradient: other.bannerGradient ?? bannerGradient,
        coverflowCardFill: other.coverflowCardFill ?? coverflowCardFill,
        coverflowTitleStyle: other.coverflowTitleStyle ?? coverflowTitleStyle,
        coverflowArtistStyle: other.coverflowArtistStyle ?? coverflowArtistStyle,
        fontFamily: other.fontFamily ?? fontFamily,
      );

  @override
  TwistMusicTheme copyWith({
    Color? laneBackground,
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    TextStyle? cardTitleStyle,
    TextStyle? cardArtistStyle,
    TextStyle? miniPlayerTitleStyle,
    Color? miniPlayerBackground,
    Color? miniPlayerForeground,
    Color? artworkPlaceholder,
    Color? promptAccent,
    Gradient? bannerGradient,
    Color? coverflowCardFill,
    TextStyle? coverflowTitleStyle,
    TextStyle? coverflowArtistStyle,
    String? fontFamily,
  }) =>
      TwistMusicTheme(
        laneBackground: laneBackground ?? this.laneBackground,
        headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
        headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
        cardTitleStyle: cardTitleStyle ?? this.cardTitleStyle,
        cardArtistStyle: cardArtistStyle ?? this.cardArtistStyle,
        miniPlayerTitleStyle: miniPlayerTitleStyle ?? this.miniPlayerTitleStyle,
        miniPlayerBackground: miniPlayerBackground ?? this.miniPlayerBackground,
        miniPlayerForeground: miniPlayerForeground ?? this.miniPlayerForeground,
        artworkPlaceholder: artworkPlaceholder ?? this.artworkPlaceholder,
        promptAccent: promptAccent ?? this.promptAccent,
        bannerGradient: bannerGradient ?? this.bannerGradient,
        coverflowCardFill: coverflowCardFill ?? this.coverflowCardFill,
        coverflowTitleStyle: coverflowTitleStyle ?? this.coverflowTitleStyle,
        coverflowArtistStyle: coverflowArtistStyle ?? this.coverflowArtistStyle,
        fontFamily: fontFamily ?? this.fontFamily,
      );

  @override
  TwistMusicTheme lerp(ThemeExtension<TwistMusicTheme>? other, double t) {
    if (other is! TwistMusicTheme) return this;
    return TwistMusicTheme(
      laneBackground: Color.lerp(laneBackground, other.laneBackground, t),
      headerTitleStyle: TextStyle.lerp(headerTitleStyle, other.headerTitleStyle, t),
      headerSubtitleStyle: TextStyle.lerp(headerSubtitleStyle, other.headerSubtitleStyle, t),
      cardTitleStyle: TextStyle.lerp(cardTitleStyle, other.cardTitleStyle, t),
      cardArtistStyle: TextStyle.lerp(cardArtistStyle, other.cardArtistStyle, t),
      miniPlayerTitleStyle: TextStyle.lerp(miniPlayerTitleStyle, other.miniPlayerTitleStyle, t),
      miniPlayerBackground: Color.lerp(miniPlayerBackground, other.miniPlayerBackground, t),
      miniPlayerForeground: Color.lerp(miniPlayerForeground, other.miniPlayerForeground, t),
      artworkPlaceholder: Color.lerp(artworkPlaceholder, other.artworkPlaceholder, t),
      promptAccent: Color.lerp(promptAccent, other.promptAccent, t),
      bannerGradient: Gradient.lerp(bannerGradient, other.bannerGradient, t),
      coverflowCardFill: Color.lerp(coverflowCardFill, other.coverflowCardFill, t),
      coverflowTitleStyle: TextStyle.lerp(coverflowTitleStyle, other.coverflowTitleStyle, t),
      coverflowArtistStyle: TextStyle.lerp(coverflowArtistStyle, other.coverflowArtistStyle, t),
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
    );
  }
}
