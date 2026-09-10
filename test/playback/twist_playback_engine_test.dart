import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/twist_music_player.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeBackend backend;
  late FakeSession session;
  late TwistPlaybackEngine engine;
  final errors = <Object>[];

  TwistPlaybackEngine build({TwistDownloadPromptPolicy? policy}) =>
      TwistPlaybackEngine(
        backend: backend,
        session: session,
        promptPolicy: policy ?? TwistDownloadPromptPolicy.fallback,
        onError: (error, _) => errors.add(error),
      );

  setUp(() {
    backend = FakeBackend();
    session = FakeSession();
    errors.clear();
    engine = build();
  });

  tearDown(() => engine.dispose());

  Future<void> playAndReady(TwistTrack t, List<TwistTrack> queue) async {
    await engine.play(t, queue: queue, laneTitle: 'Lane', laneSubTitle: 'Sub');
    await backend.emitReady();
  }

  group('initial state', () {
    test('starts idle with an empty queue', () {
      final s = engine.snapshot;
      expect(s.status, TwistPlaybackStatus.idle);
      expect(s.queue, isEmpty);
      expect(s.queueIndex, 0);
      expect(s.progressSeconds, 0);
      expect(s.isActive, isFalse);
      expect(engine.previewSeconds, 30);
    });

    test('commands are no-ops from idle', () async {
      await engine.pause();
      await engine.resume();
      await engine.next();
      await engine.previous();
      await engine.seek(10);
      await engine.stop();
      expect(engine.snapshot.status, TwistPlaybackStatus.idle);
      expect(backend.log, ['stop']);
    });
  });

  group('play', () {
    test('sets the queue, loads the preview and goes playing on ready', () async {
      final queue = tracks(3);
      await engine.play(queue[1], queue: queue, laneTitle: 'Lane');
      expect(engine.snapshot.status, TwistPlaybackStatus.loading);
      expect(engine.snapshot.queueIndex, 1);
      expect(engine.snapshot.currentTrack, queue[1]);
      expect(engine.snapshot.laneTitle, 'Lane');
      expect(backend.loadedUrl, queue[1].previewUrl);
      expect(backend.playing, isTrue);
      expect(session.activations, 1);

      await backend.emitReady();
      expect(engine.snapshot.status, TwistPlaybackStatus.playing);
    });

    test('a track outside the queue plays at index 0', () async {
      await engine.play(track(99), queue: tracks(2));
      expect(engine.snapshot.queueIndex, 0);
      expect(engine.snapshot.currentTrack, track(99));
    });

    test('lane titles are kept when a later play omits them', () async {
      final queue = tracks(2);
      await engine.play(queue[0], queue: queue, laneTitle: 'Lane', laneSubTitle: 'Sub');
      await engine.play(queue[1], queue: queue);
      expect(engine.snapshot.laneTitle, 'Lane');
      expect(engine.snapshot.laneSubTitle, 'Sub');
    });

    test('a refused audio session yields an error state', () async {
      session.refuse = true;
      await engine.play(track(1), queue: tracks(1));
      expect(engine.snapshot.status, TwistPlaybackStatus.error);
      expect(engine.snapshot.errorMessage, TwistPlaybackErrors.sessionActivationFailed);
      expect(backend.loads, 0);
      expect(errors, isNotEmpty);
    });

    test('a failing load yields an error state', () async {
      backend.failLoad = true;
      await engine.play(track(1), queue: tracks(1));
      expect(engine.snapshot.status, TwistPlaybackStatus.error);
      expect(engine.snapshot.errorMessage, TwistPlaybackErrors.playbackFailed);
    });

    test('a backend error while active yields an error state', () async {
      await playAndReady(track(1), tracks(1));
      await backend.emitError(Exception('decoder'));
      expect(engine.snapshot.status, TwistPlaybackStatus.error);
    });
  });

  group('pause and resume', () {
    test('pause only from playing, releasing the session', () async {
      await engine.play(track(1), queue: tracks(1));
      await engine.pause();
      expect(engine.snapshot.status, TwistPlaybackStatus.loading);

      await backend.emitReady();
      await engine.pause();
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      expect(backend.playing, isFalse);
      expect(session.deactivations, 1);
    });

    test('resume only from paused, re-activating the session', () async {
      await playAndReady(track(1), tracks(1));
      await engine.resume();
      expect(session.activations, 1);

      await engine.pause();
      await engine.resume();
      expect(engine.snapshot.status, TwistPlaybackStatus.playing);
      expect(session.activations, 2);
      expect(backend.playing, isTrue);
    });

    test('ready while paused does not resume', () async {
      await playAndReady(track(1), tracks(1));
      await engine.pause();
      await backend.emitReady();
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
    });

    test('toggle cycles playing and paused, and replays from completed', () async {
      await playAndReady(track(1), tracks(1));
      await engine.togglePlayPause();
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      await engine.togglePlayPause();
      expect(engine.snapshot.status, TwistPlaybackStatus.playing);

      engine.configureDownloadPrompt(const TwistDownloadPromptPolicy(isEnabled: false));
      await backend.emitCompleted();
      expect(engine.snapshot.status, TwistPlaybackStatus.completed);
      await engine.togglePlayPause();
      expect(engine.snapshot.status, TwistPlaybackStatus.loading);
      expect(backend.loads, 2);
      expect(engine.snapshot.progressSeconds, 0);
    });
  });

  group('queue navigation (prompt disabled)', () {
    const noPrompt = TwistDownloadPromptPolicy(isEnabled: false);

    setUp(() => engine.configureDownloadPrompt(noPrompt));

    test('next wraps around', () async {
      final queue = tracks(3);
      await playAndReady(queue[2], queue);
      await engine.next();
      expect(engine.snapshot.queueIndex, 0);
      expect(engine.snapshot.currentTrack, queue[0]);
    });

    test('previous restarts past three seconds, otherwise wraps back', () async {
      final queue = tracks(3);
      await playAndReady(queue[0], queue);
      await backend.emitPosition(4);
      await engine.previous();
      expect(engine.snapshot.queueIndex, 0);
      expect(engine.snapshot.currentTrack, queue[0]);
      expect(backend.loads, 2);

      await backend.emitReady();
      await backend.emitPosition(1);
      await engine.previous();
      expect(engine.snapshot.queueIndex, 2);
      expect(engine.snapshot.currentTrack, queue[2]);
    });

    test('completion advances without wrap and ends in completed', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await backend.emitCompleted();
      expect(engine.snapshot.queueIndex, 1);
      expect(engine.snapshot.status, TwistPlaybackStatus.loading);

      await backend.emitReady();
      await backend.emitCompleted();
      expect(engine.snapshot.queueIndex, 1);
      expect(engine.snapshot.status, TwistPlaybackStatus.completed);
      expect(engine.snapshot.progressSeconds, 30);
    });

    test('a position past the preview length counts as completion', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await backend.emitPosition(31);
      expect(backend.log, contains('pause'));
      expect(engine.snapshot.queueIndex, 1);
    });

    test('queue pick plays the track keeping the lane title', () async {
      final queue = tracks(3);
      await playAndReady(queue[0], queue);
      await engine.selectFromQueue(queue[2]);
      expect(engine.snapshot.queueIndex, 2);
      expect(engine.snapshot.laneTitle, 'Lane');
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
    });
  });

  group('progress and seek', () {
    test('progress is clamped to the preview length', () async {
      await playAndReady(track(1), tracks(1));
      await backend.emitPosition(12.5);
      expect(engine.snapshot.progressSeconds, 12.5);
    });

    test('seek clamps and updates progress', () async {
      await playAndReady(track(1), tracks(1));
      await engine.seek(45);
      expect(engine.snapshot.progressSeconds, 30);
      expect(backend.position, const Duration(seconds: 30));
      await engine.seek(-5);
      expect(engine.snapshot.progressSeconds, 0);
    });
  });

  group('download prompt', () {
    test('completion raises the prompt once per session by default', () async {
      final queue = tracks(3);
      await playAndReady(queue[0], queue);
      await backend.emitCompleted();
      final s = engine.snapshot;
      expect(s.status, TwistPlaybackStatus.completed);
      expect(s.pendingDownloadPrompt?.reason, TwistDownloadPromptReason.completed);
      expect(s.pendingDownloadPrompt?.track, queue[0]);
      expect(session.deactivations, 1);

      await engine.resolveDownloadPrompt(didDownload: false);
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      expect(engine.snapshot.queueIndex, 1);

      await backend.emitReady();
      await backend.emitCompleted();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      expect(engine.snapshot.queueIndex, 2);
    });

    test('interval prompt pauses playback and resumes after "not now"', () async {
      engine.configureDownloadPrompt(
          const TwistDownloadPromptPolicy(maxCount: 5, intervalSeconds: 15));
      await playAndReady(track(1), tracks(2));
      await backend.emitPosition(14.9);
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      await backend.emitPosition(15);
      expect(engine.snapshot.pendingDownloadPrompt?.reason, TwistDownloadPromptReason.interval);
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      expect(backend.playing, isFalse);

      await engine.resolveDownloadPrompt(didDownload: false);
      expect(engine.snapshot.status, TwistPlaybackStatus.playing);
      expect(backend.playing, isTrue);
    });

    test('next raises the skip prompt and advances after "not now"', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt?.reason, TwistDownloadPromptReason.skip);
      expect(engine.snapshot.queueIndex, 0);
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);

      await engine.resolveDownloadPrompt(didDownload: false);
      expect(engine.snapshot.queueIndex, 1);
      expect(engine.snapshot.status, TwistPlaybackStatus.loading);
    });

    test('queue pick parks the track behind the prompt', () async {
      final queue = tracks(3);
      await playAndReady(queue[0], queue);
      await engine.selectFromQueue(queue[2]);
      expect(engine.snapshot.pendingDownloadPrompt?.reason,
          TwistDownloadPromptReason.queueSelection);
      expect(engine.snapshot.currentTrack, queue[0]);

      await engine.resolveDownloadPrompt(didDownload: false);
      expect(engine.snapshot.currentTrack, queue[2]);
      expect(engine.snapshot.queueIndex, 2);
    });

    test('previous never prompts', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await engine.previous();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      expect(engine.snapshot.queueIndex, 1);
    });

    test('"download" leaves the player paused', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await engine.next();
      await engine.resolveDownloadPrompt(didDownload: true);
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      expect(engine.snapshot.queueIndex, 0);
    });

    test('a track prompts at most once, maxCount caps the session', () async {
      engine.configureDownloadPrompt(
          const TwistDownloadPromptPolicy(maxCount: 2, intervalSeconds: 5));
      final queue = tracks(3);
      await playAndReady(queue[0], queue);
      await backend.emitPosition(5);
      expect(engine.snapshot.pendingDownloadPrompt, isNotNull);
      await engine.resolveDownloadPrompt(didDownload: false);
      await backend.emitPosition(6);
      expect(engine.snapshot.pendingDownloadPrompt, isNull);

      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
      await backend.emitReady();
      await backend.emitPosition(5);
      expect(engine.snapshot.pendingDownloadPrompt, isNotNull);
      await engine.resolveDownloadPrompt(didDownload: false);

      await engine.next();
      await backend.emitReady();
      await backend.emitPosition(5);
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
    });

    test('a disabled policy never prompts', () async {
      engine.configureDownloadPrompt(const TwistDownloadPromptPolicy(isEnabled: false));
      await playAndReady(track(1), tracks(2));
      await backend.emitPosition(30);
      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
    });

    test('resetSessionFlags allows prompting again', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await engine.next();
      await engine.resolveDownloadPrompt(didDownload: false);
      await backend.emitReady();
      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);

      engine.resetSessionFlags();
      await backend.emitReady();
      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt, isNotNull);
    });
  });

  group('stop', () {
    test('returns to idle, keeps the queue and the session counters', () async {
      final queue = tracks(2);
      await playAndReady(queue[0], queue);
      await engine.next();
      await engine.resolveDownloadPrompt(didDownload: false);
      await engine.stop();

      final s = engine.snapshot;
      expect(s.status, TwistPlaybackStatus.idle);
      expect(s.currentTrack, isNull);
      expect(s.progressSeconds, 0);
      expect(s.laneTitle, isNull);
      expect(s.queue, hasLength(2));
      expect(session.deactivations, greaterThanOrEqualTo(1));

      await engine.play(queue[0], queue: queue);
      await backend.emitReady();
      await engine.next();
      expect(engine.snapshot.pendingDownloadPrompt, isNull);
    });

    test('stale backend events after stop are ignored', () async {
      await playAndReady(track(1), tracks(1));
      await engine.stop();
      await backend.emitReady();
      await backend.emitPosition(10);
      expect(engine.snapshot.status, TwistPlaybackStatus.idle);
      expect(engine.snapshot.progressSeconds, 0);
    });
  });

  group('session events', () {
    test('an interruption pauses and resumes only with the resume hint', () async {
      await playAndReady(track(1), tracks(1));
      await session.interrupt();
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      await session.endInterruption(shouldResume: false);
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
      await session.endInterruption(shouldResume: true);
      expect(engine.snapshot.status, TwistPlaybackStatus.playing);
    });

    test('becoming noisy pauses', () async {
      await playAndReady(track(1), tracks(1));
      await session.becomeNoisy();
      expect(engine.snapshot.status, TwistPlaybackStatus.paused);
    });
  });

  group('expansion latch', () {
    test('arms once per session and clears on acknowledge', () async {
      engine.requestFirstTimeExpansion();
      expect(engine.snapshot.pendingExpansionRequest, isTrue);
      engine.acknowledgeExpansionRequest();
      expect(engine.snapshot.pendingExpansionRequest, isFalse);
      engine.requestFirstTimeExpansion();
      expect(engine.snapshot.pendingExpansionRequest, isFalse);
      engine.resetSessionFlags();
      engine.requestFirstTimeExpansion();
      expect(engine.snapshot.pendingExpansionRequest, isTrue);
    });
  });

  test('a throwing error callback never breaks playback', () async {
    final throwing = TwistPlaybackEngine(
      backend: backend,
      session: session,
      onError: (_, __) => throw StateError('host bug'),
    );
    backend.failLoad = true;
    await throwing.play(track(1), queue: tracks(1));
    expect(throwing.snapshot.status, TwistPlaybackStatus.error);
    await throwing.dispose();
  });
}
