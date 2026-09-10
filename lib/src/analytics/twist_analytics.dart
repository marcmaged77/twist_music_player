import 'package:flutter/foundation.dart';

import '../config/twist_music_config.dart';
import '../data/models/twist_track.dart';

/// Event names, identical to the native iOS and Android implementations.
abstract final class TwistAnalyticsEvents {
  static const String laneLoaded = 'twist_music_lane_loaded';
  static const String trackTapped = 'twist_music_track_tapped';
  static const String playerExpanded = 'twist_music_player_expanded';
  static const String queueOpened = 'twist_music_queue_opened';
  static const String queueTrackSelected = 'twist_music_queue_track_selected';
  static const String downloadPromptShown = 'twist_music_download_prompt_shown';
  static const String downloadPromptAction = 'twist_music_download_prompt_action';
  static const String downloadClicked = 'twist_music_download_clicked';
}

/// `source` values carried by download events.
abstract final class TwistAnalyticsSources {
  static const String promptMini = 'prompt_mini';
  static const String promptFullScreen = 'prompt_full_screen';
  static const String fullScreenBanner = 'full_screen_banner';
}

/// Builds the native event payloads and hands them to the host callback.
/// A throwing callback is swallowed so it can never affect playback.
class TwistAnalytics {
  const TwistAnalytics(this._callback);

  final TwistAnalyticsCallback? _callback;

  void laneLoaded(int trackCount) =>
      _send(TwistAnalyticsEvents.laneLoaded, {'track_count': trackCount});

  void trackTapped(TwistTrack track, {required int position}) =>
      _send(TwistAnalyticsEvents.trackTapped, {
        'action': 'swimlane',
        'label': track.title,
        'track_id': '${track.id}',
        'artist': track.artistName,
        'position': position,
      });

  void playerExpanded(TwistTrack track, {required String via}) =>
      _send(TwistAnalyticsEvents.playerExpanded, {
        'action': via,
        'label': track.title,
        'track_id': '${track.id}',
      });

  void queueOpened(TwistTrack track, {required int queueCount}) =>
      _send(TwistAnalyticsEvents.queueOpened, {
        'label': track.title,
        'track_id': '${track.id}',
        'queue_count': queueCount,
      });

  void queueTrackSelected({
    required TwistTrack from,
    required TwistTrack to,
    required int position,
  }) =>
      _send(TwistAnalyticsEvents.queueTrackSelected, {
        'label': to.title,
        'from_track_id': '${from.id}',
        'to_track_id': '${to.id}',
        'position': position,
      });

  void downloadPromptShown(TwistTrack track, {required String source}) =>
      _send(TwistAnalyticsEvents.downloadPromptShown, {
        'label': track.title,
        'source': source,
      });

  void downloadPromptAction(TwistTrack track,
          {required String action, required String source}) =>
      _send(TwistAnalyticsEvents.downloadPromptAction, {
        'action': action,
        'label': track.title,
        'source': source,
      });

  void downloadClicked(TwistTrack? track, {required String source}) =>
      _send(TwistAnalyticsEvents.downloadClicked, {
        if (track != null) 'label': track.title,
        'source': source,
        'track_id': track == null ? '' : '${track.id}',
      });

  void _send(String name, Map<String, Object> parameters) {
    final callback = _callback;
    if (callback == null) return;
    try {
      callback(name, Map<String, Object>.unmodifiable(parameters));
    } catch (error) {
      debugPrint('[twist_music_player] analytics callback threw for $name: $error');
    }
  }
}
