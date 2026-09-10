/// Lifecycle of the single preview player.
enum TwistPlaybackStatus {
  /// No track loaded; the mini player is hidden.
  idle,

  /// A track is being prepared.
  loading,

  /// Producing sound.
  playing,

  /// Loaded at a known position, silent.
  paused,

  /// The preview reached its end, either because a download prompt was due or
  /// because the queue has no next track.
  completed,

  /// Non-recoverable until the next `play`.
  error;

  bool get isActive => this != TwistPlaybackStatus.idle;
  bool get isPlaying => this == TwistPlaybackStatus.playing;
}

/// Why a download prompt was raised; decides what happens once it closes.
enum TwistDownloadPromptReason {
  /// Playback position crossed the policy interval.
  interval,

  /// The preview finished.
  completed,

  /// The user pressed Next.
  skip,

  /// The user picked a track in the queue.
  queueSelection,
}

/// Error keys carried by [TwistPlaybackStatus.error].
abstract final class TwistPlaybackErrors {
  static const String sessionActivationFailed = 'audio_session_activation_failed';
  static const String playbackFailed = 'playback_failed';
}
