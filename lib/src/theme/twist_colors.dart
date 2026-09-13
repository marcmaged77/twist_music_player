import 'package:flutter/painting.dart';

/// Fixed colours of the player chrome. The lane and the full player are dark
/// regardless of the host theme.
abstract final class TwistColors {
  /// Twist brand blue, sampled from the wordmark.
  static const Color accent = Color(0xFF0021A5);
  static const Color bannerViolet = Color(0xFF8A1A6A);
  static const Color bannerRed = Color(0xFFEC1C24);
  static const Color cardShadow = Color(0x40000000);
  static const Color skeletonBase = Color(0xFFE4E5EB);
  static const Color skeletonHighlight = Color(0xFFF4F5F9);
  static const Color darkNavy = Color(0xFF0F1224);
  static const Color fallbackSecondary = Color(0xFF1A1A33);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkTitle = Color(0xD9FFFFFF);
  static const Color onDarkMuted = Color(0x99FFFFFF);
  static const Color onDarkSoft = Color(0xB3FFFFFF);
  static const Color onDarkFaint = Color(0x33FFFFFF);
  static const Color badgeScrim = Color(0x8C000000);
  static const Color cardScrim = Color(0xC7000000);
  static const Color artworkPlaceholder = Color(0xFFE5E5EA);
  static const Color artworkPlaceholderDark = Color(0xFF2C2C3A);
  static const Color promoCardFill = Color(0x14FFFFFF);
  static const Color promoCtaFill = Color(0x33FFFFFF);
}
