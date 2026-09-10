import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'playback_backend.dart';

/// Production [PlaybackBackend] over a single `just_audio` [AudioPlayer].
class JustAudioBackend implements PlaybackBackend {
  JustAudioBackend({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _eventSubscription = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stack) => _errors.add(error),
    );
  }

  final AudioPlayer _player;
  final _errors = StreamController<Object>.broadcast();
  late final StreamSubscription<PlaybackEvent> _eventSubscription;

  @override
  Stream<PlaybackBackendState> get stateStream =>
      _player.processingStateStream.map(_mapState).distinct();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Object> get errorStream => _errors.stream;

  @override
  Future<void> load(Uri url) async {
    try {
      await _player.setAudioSource(AudioSource.uri(url), preload: true);
    } on PlayerInterruptedException {
      // A newer load superseded this one; the engine ignores stale loads.
    }
  }

  @override
  Future<void> play() async {
    // `AudioPlayer.play` completes when playback pauses or finishes, so it is
    // deliberately not awaited.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _eventSubscription.cancel();
    await _errors.close();
    await _player.dispose();
  }

  static PlaybackBackendState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return PlaybackBackendState.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return PlaybackBackendState.loading;
      case ProcessingState.ready:
        return PlaybackBackendState.ready;
      case ProcessingState.completed:
        return PlaybackBackendState.completed;
    }
  }
}
