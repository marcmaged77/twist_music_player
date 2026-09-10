/// Coarse state of the underlying audio player.
enum PlaybackBackendState { idle, loading, ready, completed }

/// The thin surface the engine needs from an audio player.
///
/// `just_audio` is the production implementation; tests use an in-memory fake.
abstract class PlaybackBackend {
  Stream<PlaybackBackendState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Object> get errorStream;

  /// Prepares [url]. Completes once the item is ready or throws.
  Future<void> load(Uri url);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Releases the current item and returns to [PlaybackBackendState.idle].
  Future<void> stop();

  Future<void> dispose();
}

/// An audio-focus interruption from the platform.
class PlaybackInterruption {
  const PlaybackInterruption.began() : began = true, shouldResume = false;
  const PlaybackInterruption.ended({required this.shouldResume}) : began = false;

  final bool began;

  /// Only meaningful when [began] is false.
  final bool shouldResume;
}

/// Audio session and focus handling, kept behind an interface so the engine
/// can be unit-tested without platform channels.
abstract class PlaybackSessionController {
  /// Claims the session or audio focus. Throws when the platform refuses.
  Future<void> activate();

  /// Releases the session so other apps may resume.
  Future<void> deactivate();

  Stream<PlaybackInterruption> get interruptions;

  /// Headphones unplugged, Bluetooth disconnected.
  Stream<void> get becomingNoisy;

  Future<void> dispose();
}
