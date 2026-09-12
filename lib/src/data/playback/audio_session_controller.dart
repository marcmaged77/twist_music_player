import 'dart:async';

import 'package:audio_session/audio_session.dart';

import 'playback_backend.dart';

/// [PlaybackSessionController] over `audio_session`: playback category on
/// iOS, media audio focus on Android, interruptions and route changes.
class AudioSessionPlaybackController implements PlaybackSessionController {
  AudioSessionPlaybackController();

  AudioSession? _session;
  Future<AudioSession>? _configuring;

  Future<AudioSession> _ensureConfigured() {
    return _configuring ??= () async {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _session = session;
      return session;
    }();
  }

  @override
  Future<void> activate() async {
    final session = await _ensureConfigured();
    final granted = await session.setActive(true);
    if (!granted) {
      throw StateError('Audio session activation was refused');
    }
  }

  @override
  Future<void> deactivate() async {
    final session = _session;
    if (session == null) return;
    await session.setActive(false);
  }

  @override
  Stream<PlaybackInterruption> get interruptions async* {
    final session = await _ensureConfigured();
    await for (final event in session.interruptionEventStream) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.duck) continue;
        yield const PlaybackInterruption.began();
      } else {
        yield PlaybackInterruption.ended(shouldResume: event.type == AudioInterruptionType.pause);
      }
    }
  }

  @override
  Stream<void> get becomingNoisy async* {
    final session = await _ensureConfigured();
    yield* session.becomingNoisyEventStream;
  }

  @override
  Future<void> dispose() async {}
}
