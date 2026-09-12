import 'package:flutter/widgets.dart';

import '../data/lane/twist_lane_source.dart';
import 'twist_download_prompt_policy.dart';

/// Receives every analytics event with its native name and parameters.
typedef TwistAnalyticsCallback = void Function(String name, Map<String, Object> parameters);

/// Receives lane and playback failures.
typedef TwistErrorCallback = void Function(Object error, StackTrace stack);

/// Logos the host supplies; the package ships none of Twist's brand assets.
class TwistBranding {
  const TwistBranding({this.headerLogo, this.promoLogo});

  /// Shown in the swimlane header next to the lane title.
  final ImageProvider? headerLogo;

  /// Shown in the full-player promo card and the download prompt.
  final ImageProvider? promoLogo;
}

/// Everything the host tells the package. Nothing is discovered from the app.
class TwistMusicConfig {
  const TwistMusicConfig({
    required this.laneSource,
    required this.downloadFallbackUrl,
    this.onAnalyticsEvent,
    this.onError,
    this.branding,
    this.fallbackPromptPolicy = TwistDownloadPromptPolicy.fallback,
    this.androidNotificationChannelId = 'twist_music_player.audio',
    this.androidNotificationIcon = 'mipmap/ic_launcher',
    this.previewDuration = const Duration(seconds: 30),
  });

  /// Where the lane comes from; see [HttpTwistLaneSource].
  final TwistLaneSource laneSource;

  /// Store page opened when the lane carries no usable download link.
  final Uri downloadFallbackUrl;

  final TwistAnalyticsCallback? onAnalyticsEvent;
  final TwistErrorCallback? onError;
  final TwistBranding? branding;

  /// Prompt cadence until the lane response supplies one.
  final TwistDownloadPromptPolicy fallbackPromptPolicy;

  /// audio_service notification channel id on Android.
  final String androidNotificationChannelId;

  /// Android drawable resource for the notification small icon.
  final String androidNotificationIcon;

  /// Authoritative preview length.
  final Duration previewDuration;
}
