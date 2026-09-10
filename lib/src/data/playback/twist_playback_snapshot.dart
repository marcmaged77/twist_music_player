import '../models/twist_track.dart';
import 'twist_playback_status.dart';

/// A pending "download Twist" prompt the UI must present.
class TwistDownloadPromptRequest {
  const TwistDownloadPromptRequest({required this.reason, required this.track});

  final TwistDownloadPromptReason reason;
  final TwistTrack track;

  @override
  bool operator ==(Object other) =>
      other is TwistDownloadPromptRequest &&
      other.reason == reason &&
      other.track == track;

  @override
  int get hashCode => Object.hash(reason, track);
}

/// Immutable view of the engine, published on every change.
class TwistPlaybackSnapshot {
  const TwistPlaybackSnapshot({
    this.status = TwistPlaybackStatus.idle,
    this.errorMessage,
    this.currentTrack,
    this.queue = const <TwistTrack>[],
    this.queueIndex = 0,
    this.progressSeconds = 0,
    this.laneTitle,
    this.laneSubTitle,
    this.pendingDownloadPrompt,
    this.pendingExpansionRequest = false,
  });

  final TwistPlaybackStatus status;
  final String? errorMessage;
  final TwistTrack? currentTrack;
  final List<TwistTrack> queue;
  final int queueIndex;

  /// Clamped to the preview duration.
  final double progressSeconds;

  final String? laneTitle;
  final String? laneSubTitle;
  final TwistDownloadPromptRequest? pendingDownloadPrompt;

  /// True once after the first swimlane tap of the session; the host UI
  /// acknowledges it by opening the full player.
  final bool pendingExpansionRequest;

  bool get isActive => status.isActive;
  bool get isPlaying => status.isPlaying;
  bool get hasQueue => queue.isNotEmpty;

  TwistPlaybackSnapshot copyWith({
    TwistPlaybackStatus? status,
    Object? errorMessage = _unset,
    Object? currentTrack = _unset,
    List<TwistTrack>? queue,
    int? queueIndex,
    double? progressSeconds,
    Object? laneTitle = _unset,
    Object? laneSubTitle = _unset,
    Object? pendingDownloadPrompt = _unset,
    bool? pendingExpansionRequest,
  }) {
    return TwistPlaybackSnapshot(
      status: status ?? this.status,
      errorMessage: errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      currentTrack:
          currentTrack == _unset ? this.currentTrack : currentTrack as TwistTrack?,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      laneTitle: laneTitle == _unset ? this.laneTitle : laneTitle as String?,
      laneSubTitle:
          laneSubTitle == _unset ? this.laneSubTitle : laneSubTitle as String?,
      pendingDownloadPrompt: pendingDownloadPrompt == _unset
          ? this.pendingDownloadPrompt
          : pendingDownloadPrompt as TwistDownloadPromptRequest?,
      pendingExpansionRequest:
          pendingExpansionRequest ?? this.pendingExpansionRequest,
    );
  }

  static const Object _unset = Object();

  @override
  String toString() =>
      'TwistPlaybackSnapshot($status, ${currentTrack?.title}, ${progressSeconds.toStringAsFixed(1)}s, '
      'queue ${queueIndex + 1}/${queue.length}, prompt: ${pendingDownloadPrompt?.reason})';
}
