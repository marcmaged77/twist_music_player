import 'dart:async';

import 'package:audio_service/audio_service.dart';

import '../models/twist_track.dart';
import 'twist_playback_engine.dart';
import 'twist_playback_snapshot.dart';
import 'twist_playback_status.dart';

/// Bridges the engine to the lock screen, Control Center and the Android
/// media notification. Remote commands are forwarded to the engine so they
/// pass through the same download-prompt gate as on-screen taps.
class TwistAudioHandler extends BaseAudioHandler with SeekHandler {
  TwistAudioHandler(this._engine) {
    _subscription = _engine.stream.listen(_sync);
    _sync(_engine.snapshot);
  }

  final TwistPlaybackEngine _engine;
  late final StreamSubscription<TwistPlaybackSnapshot> _subscription;

  TwistTrack? _publishedTrack;
  TwistPlaybackStatus? _publishedStatus;
  int? _publishedIndex;
  double _publishedProgress = 0;

  void _sync(TwistPlaybackSnapshot snapshot) {
    final track = snapshot.currentTrack;
    if (track != _publishedTrack) {
      _publishedTrack = track;
      mediaItem.add(track == null ? null : _mediaItem(track));
    }

    // Position is extrapolated by the platform from the last update, so only
    // publish on status changes, track changes and seeks (jumps over 1.5 s).
    final jumped = (snapshot.progressSeconds - _publishedProgress).abs() > 1.5;
    final changed = snapshot.status != _publishedStatus ||
        snapshot.queueIndex != _publishedIndex ||
        track != _publishedTrack;
    if (!changed && !jumped) {
      _publishedProgress = snapshot.progressSeconds;
      return;
    }
    _publishedStatus = snapshot.status;
    _publishedIndex = snapshot.queueIndex;
    _publishedProgress = snapshot.progressSeconds;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        snapshot.isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _processingState(snapshot.status),
      playing: snapshot.isPlaying,
      updatePosition: Duration(milliseconds: (snapshot.progressSeconds * 1000).round()),
      queueIndex: snapshot.hasQueue ? snapshot.queueIndex : null,
    ));
  }

  MediaItem _mediaItem(TwistTrack track) => MediaItem(
        id: track.previewUrl.toString(),
        title: track.title,
        artist: track.artistName,
        album: track.albumTitle,
        duration: _engine.previewDuration,
        artUri: track.preferredLockScreenArtworkUrl,
      );

  static AudioProcessingState _processingState(TwistPlaybackStatus status) {
    switch (status) {
      case TwistPlaybackStatus.idle:
        return AudioProcessingState.idle;
      case TwistPlaybackStatus.loading:
        return AudioProcessingState.loading;
      case TwistPlaybackStatus.playing:
      case TwistPlaybackStatus.paused:
        return AudioProcessingState.ready;
      case TwistPlaybackStatus.completed:
        return AudioProcessingState.completed;
      case TwistPlaybackStatus.error:
        return AudioProcessingState.error;
    }
  }

  @override
  Future<void> play() async {
    switch (_engine.snapshot.status) {
      case TwistPlaybackStatus.paused:
        await _engine.resume();
      case TwistPlaybackStatus.completed:
        await _engine.togglePlayPause();
      case TwistPlaybackStatus.idle:
      case TwistPlaybackStatus.loading:
      case TwistPlaybackStatus.playing:
      case TwistPlaybackStatus.error:
        break;
    }
  }

  @override
  Future<void> pause() => _engine.pause();

  @override
  Future<void> skipToNext() => _engine.next();

  @override
  Future<void> skipToPrevious() => _engine.previous();

  @override
  Future<void> seek(Duration position) => _engine.seek(position.inMilliseconds / 1000);

  @override
  Future<void> stop() async {
    await _engine.stop();
    await super.stop();
  }

  Future<void> dispose() => _subscription.cancel();
}
