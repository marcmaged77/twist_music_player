import 'dart:async';

import '../../config/twist_download_prompt_policy.dart';
import '../models/twist_track.dart';
import 'playback_backend.dart';
import 'twist_playback_snapshot.dart';
import 'twist_playback_status.dart';

/// Pure-Dart playback state machine: queue, progress, download-prompt cadence
/// and the first-tap expansion latch. Drives a [PlaybackBackend] and a
/// [PlaybackSessionController]; publishes [TwistPlaybackSnapshot]s.
///
/// Session-scoped counters (prompt shows, expansion latch) live for the
/// process lifetime and survive [stop]; [resetSessionFlags] clears them.
class TwistPlaybackEngine {
  TwistPlaybackEngine({
    required PlaybackBackend backend,
    required PlaybackSessionController session,
    this.previewDuration = const Duration(seconds: 30),
    TwistDownloadPromptPolicy promptPolicy = TwistDownloadPromptPolicy.fallback,
    void Function(Object error, StackTrace stack)? onError,
  })  : _backend = backend,
        _session = session,
        _promptPolicy = promptPolicy,
        _onError = onError {
    _subscriptions.addAll([
      _backend.stateStream.listen(_onBackendState),
      _backend.positionStream.listen(_onBackendPosition),
      _backend.errorStream.listen(_onBackendError),
      _session.interruptions.listen(_onInterruption),
      _session.becomingNoisy.listen((_) => _onBecomingNoisy()),
    ]);
  }

  final PlaybackBackend _backend;
  final PlaybackSessionController _session;
  final void Function(Object error, StackTrace stack)? _onError;

  /// Authoritative preview length. Progress, seeks and the lock-screen
  /// duration are clamped to it regardless of the actual file length.
  final Duration previewDuration;

  final _controller = StreamController<TwistPlaybackSnapshot>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  TwistPlaybackSnapshot _snapshot = const TwistPlaybackSnapshot();
  TwistDownloadPromptPolicy _promptPolicy;

  int _promptShowsUsedThisSession = 0;
  final Set<int> _promptShownTrackIds = <int>{};
  TwistTrack? _parkedQueueTrack;
  bool _hasAutoExpandedFromSwimlane = false;
  int _loadGeneration = 0;
  bool _disposed = false;

  TwistPlaybackSnapshot get snapshot => _snapshot;
  Stream<TwistPlaybackSnapshot> get stream => _controller.stream;
  TwistDownloadPromptPolicy get promptPolicy => _promptPolicy;
  double get previewSeconds => previewDuration.inMilliseconds / 1000;

  // Configuration -----------------------------------------------------------

  /// Installs the lane's prompt cadence. Counters are untouched.
  void configureDownloadPrompt(TwistDownloadPromptPolicy policy) {
    _promptPolicy = policy;
  }

  /// Clears the once-per-session flags (prompt count, auto-expansion).
  void resetSessionFlags() {
    _promptShowsUsedThisSession = 0;
    _promptShownTrackIds.clear();
    _hasAutoExpandedFromSwimlane = false;
    _emit(_snapshot.copyWith(pendingExpansionRequest: false));
  }

  // Playback commands -------------------------------------------------------

  /// Replaces the queue and starts [track]. Lane titles update only when
  /// provided so a queue pick keeps the lane headline.
  Future<void> play(
    TwistTrack track, {
    required List<TwistTrack> queue,
    String? laneTitle,
    String? laneSubTitle,
  }) async {
    final index = queue.indexOf(track);
    _emit(_snapshot.copyWith(
      queue: List<TwistTrack>.unmodifiable(queue),
      queueIndex: index < 0 ? 0 : index,
      laneTitle: laneTitle ?? _snapshot.laneTitle,
      laneSubTitle: laneSubTitle ?? _snapshot.laneSubTitle,
    ));
    await _load(track);
  }

  Future<void> pause() async {
    if (_snapshot.status != TwistPlaybackStatus.playing) return;
    await _guard(() => _backend.pause());
    _emit(_snapshot.copyWith(status: TwistPlaybackStatus.paused));
    await _guard(() => _session.deactivate());
  }

  Future<void> resume() async {
    if (_snapshot.status != TwistPlaybackStatus.paused) return;
    if (!await _activateSession()) return;
    await _guard(() => _backend.play());
    _emit(_snapshot.copyWith(status: TwistPlaybackStatus.playing));
  }

  Future<void> togglePlayPause() async {
    switch (_snapshot.status) {
      case TwistPlaybackStatus.playing:
        await pause();
      case TwistPlaybackStatus.paused:
        await resume();
      case TwistPlaybackStatus.completed:
        final track = _snapshot.currentTrack;
        if (track != null) await _load(track);
      case TwistPlaybackStatus.idle:
      case TwistPlaybackStatus.loading:
      case TwistPlaybackStatus.error:
        break;
    }
  }

  /// Advances with wrap-around, unless a download prompt is due for the
  /// current track, in which case the prompt is raised and the skip is
  /// deferred to [resolveDownloadPrompt].
  Future<void> next() async {
    if (!_snapshot.hasQueue) return;
    if (_canShowPromptForCurrentTrack()) {
      await _triggerDownloadPrompt(TwistDownloadPromptReason.skip);
      return;
    }
    await _performNext();
  }

  /// Restarts the current track past three seconds, otherwise steps back with
  /// wrap-around. Never raises a prompt.
  Future<void> previous() async {
    if (!_snapshot.hasQueue) return;
    final current = _snapshot.currentTrack;
    if (current != null && _snapshot.progressSeconds > 3) {
      await _load(current);
      return;
    }
    final count = _snapshot.queue.length;
    final index = (_snapshot.queueIndex - 1 + count) % count;
    _emit(_snapshot.copyWith(queueIndex: index));
    await _load(_snapshot.queue[index]);
  }

  /// Plays [track] from the current queue, or parks it behind a prompt.
  Future<void> selectFromQueue(TwistTrack track) async {
    if (_canShowPromptForCurrentTrack()) {
      _parkedQueueTrack = track;
      await _triggerDownloadPrompt(TwistDownloadPromptReason.queueSelection);
      return;
    }
    await play(track, queue: _snapshot.queue);
  }

  Future<void> seek(double seconds) async {
    if (!_snapshot.isActive || _snapshot.currentTrack == null) return;
    final clamped = seconds.clamp(0.0, previewSeconds).toDouble();
    await _guard(() =>
        _backend.seek(Duration(milliseconds: (clamped * 1000).round())));
    _emit(_snapshot.copyWith(progressSeconds: clamped));
  }

  /// Unloads the track and hides the player. The queue and the session
  /// counters are kept, matching the native behaviour.
  Future<void> stop() async {
    _loadGeneration++;
    await _guard(() => _backend.stop());
    _parkedQueueTrack = null;
    _emit(_snapshot.copyWith(
      status: TwistPlaybackStatus.idle,
      errorMessage: null,
      currentTrack: null,
      progressSeconds: 0,
      laneTitle: null,
      laneSubTitle: null,
      pendingDownloadPrompt: null,
    ));
    await _guard(() => _session.deactivate());
  }

  // Download prompt ---------------------------------------------------------

  /// Closes the pending prompt. When the user declined, playback continues
  /// according to the prompt's reason; when they chose to download, the
  /// player stays paused so the store can open over the app.
  Future<void> resolveDownloadPrompt({required bool didDownload}) async {
    final pending = _snapshot.pendingDownloadPrompt;
    if (pending == null) return;
    final parked = _parkedQueueTrack;
    _parkedQueueTrack = null;
    _emit(_snapshot.copyWith(pendingDownloadPrompt: null));
    if (didDownload) return;
    switch (pending.reason) {
      case TwistDownloadPromptReason.interval:
        await resume();
      case TwistDownloadPromptReason.completed:
        await _advanceToNextIfAvailable();
      case TwistDownloadPromptReason.skip:
        await _performNext();
      case TwistDownloadPromptReason.queueSelection:
        if (parked != null) await play(parked, queue: _snapshot.queue);
    }
  }

  // Expansion latch ---------------------------------------------------------

  /// Arms a one-time request to open the full player. No-op after the first
  /// acknowledgement of the session.
  void requestFirstTimeExpansion() {
    if (_hasAutoExpandedFromSwimlane || _snapshot.pendingExpansionRequest) return;
    _emit(_snapshot.copyWith(pendingExpansionRequest: true));
  }

  void acknowledgeExpansionRequest() {
    _hasAutoExpandedFromSwimlane = true;
    if (_snapshot.pendingExpansionRequest) {
      _emit(_snapshot.copyWith(pendingExpansionRequest: false));
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.close();
    await _guard(() => _backend.dispose());
    await _guard(() => _session.dispose());
  }

  // Internals ---------------------------------------------------------------

  Future<void> _load(TwistTrack track) async {
    final generation = ++_loadGeneration;
    _parkedQueueTrack = null;
    _emit(_snapshot.copyWith(
      status: TwistPlaybackStatus.loading,
      errorMessage: null,
      currentTrack: track,
      progressSeconds: 0,
      pendingDownloadPrompt: null,
    ));
    if (!await _activateSession()) return;
    try {
      await _backend.load(track.previewUrl);
      if (generation != _loadGeneration) return;
      await _backend.play();
    } catch (error, stack) {
      if (generation != _loadGeneration) return;
      _report(error, stack);
      _emit(_snapshot.copyWith(
        status: TwistPlaybackStatus.error,
        errorMessage: TwistPlaybackErrors.playbackFailed,
      ));
    }
  }

  Future<bool> _activateSession() async {
    try {
      await _session.activate();
      return true;
    } catch (error, stack) {
      _report(error, stack);
      _emit(_snapshot.copyWith(
        status: TwistPlaybackStatus.error,
        errorMessage: TwistPlaybackErrors.sessionActivationFailed,
      ));
      return false;
    }
  }

  Future<void> _performNext() async {
    final count = _snapshot.queue.length;
    if (count == 0) return;
    final index = (_snapshot.queueIndex + 1) % count;
    _emit(_snapshot.copyWith(queueIndex: index));
    await _load(_snapshot.queue[index]);
  }

  Future<void> _advanceToNextIfAvailable() async {
    final index = _snapshot.queueIndex + 1;
    if (index >= _snapshot.queue.length) {
      _emit(_snapshot.copyWith(status: TwistPlaybackStatus.completed));
      return;
    }
    _emit(_snapshot.copyWith(queueIndex: index));
    await _load(_snapshot.queue[index]);
  }

  bool _canShowPromptForCurrentTrack() {
    final track = _snapshot.currentTrack;
    if (track == null) return false;
    return _promptPolicy.isActive &&
        _promptShowsUsedThisSession < _promptPolicy.maxCount &&
        !_promptShownTrackIds.contains(track.id);
  }

  Future<void> _triggerDownloadPrompt(TwistDownloadPromptReason reason) async {
    final track = _snapshot.currentTrack;
    if (track == null) return;
    _promptShowsUsedThisSession++;
    _promptShownTrackIds.add(track.id);
    var status = _snapshot.status;
    if (reason != TwistDownloadPromptReason.completed &&
        status == TwistPlaybackStatus.playing) {
      await _guard(() => _backend.pause());
      status = TwistPlaybackStatus.paused;
    }
    await _guard(() => _session.deactivate());
    _emit(_snapshot.copyWith(
      status: status,
      pendingDownloadPrompt:
          TwistDownloadPromptRequest(reason: reason, track: track),
    ));
  }

  Future<void> _maybeTriggerIntervalPrompt() async {
    if (_snapshot.pendingDownloadPrompt != null) return;
    if (_snapshot.status != TwistPlaybackStatus.playing) return;
    if (_snapshot.progressSeconds < _promptPolicy.intervalSeconds) return;
    if (!_canShowPromptForCurrentTrack()) return;
    await _triggerDownloadPrompt(TwistDownloadPromptReason.interval);
  }

  Future<void> _onPreviewCompleted() async {
    _emit(_snapshot.copyWith(progressSeconds: previewSeconds));
    if (_canShowPromptForCurrentTrack()) {
      _emit(_snapshot.copyWith(status: TwistPlaybackStatus.completed));
      await _triggerDownloadPrompt(TwistDownloadPromptReason.completed);
      return;
    }
    await _advanceToNextIfAvailable();
  }

  // Backend and session events ---------------------------------------------

  void _onBackendState(PlaybackBackendState state) {
    switch (state) {
      case PlaybackBackendState.ready:
        if (_snapshot.status == TwistPlaybackStatus.loading) {
          _emit(_snapshot.copyWith(status: TwistPlaybackStatus.playing));
        }
      case PlaybackBackendState.completed:
        if (_snapshot.status == TwistPlaybackStatus.playing ||
            _snapshot.status == TwistPlaybackStatus.loading) {
          unawaited(_onPreviewCompleted());
        }
      case PlaybackBackendState.idle:
      case PlaybackBackendState.loading:
        break;
    }
  }

  void _onBackendPosition(Duration position) {
    if (!_snapshot.isActive || _snapshot.currentTrack == null) return;
    final seconds = position.inMilliseconds / 1000;
    if (seconds >= previewSeconds &&
        _snapshot.status == TwistPlaybackStatus.playing) {
      unawaited(_guard(() => _backend.pause()));
      unawaited(_onPreviewCompleted());
      return;
    }
    _emit(_snapshot.copyWith(
        progressSeconds: seconds.clamp(0.0, previewSeconds).toDouble()));
    unawaited(_maybeTriggerIntervalPrompt());
  }

  void _onBackendError(Object error) {
    if (!_snapshot.isActive) return;
    _report(error, StackTrace.current);
    _emit(_snapshot.copyWith(
      status: TwistPlaybackStatus.error,
      errorMessage: TwistPlaybackErrors.playbackFailed,
    ));
  }

  void _onInterruption(PlaybackInterruption event) {
    if (event.began) {
      if (_snapshot.status != TwistPlaybackStatus.playing) return;
      unawaited(_guard(() => _backend.pause()));
      _emit(_snapshot.copyWith(status: TwistPlaybackStatus.paused));
      return;
    }
    if (event.shouldResume && _snapshot.status == TwistPlaybackStatus.paused) {
      unawaited(_guard(() => _backend.play()));
      _emit(_snapshot.copyWith(status: TwistPlaybackStatus.playing));
    }
  }

  void _onBecomingNoisy() {
    unawaited(pause());
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      _report(error, stack);
    }
  }

  void _report(Object error, StackTrace stack) {
    try {
      _onError?.call(error, stack);
    } catch (_) {
      // A failing host callback must never affect playback.
    }
  }

  void _emit(TwistPlaybackSnapshot next) {
    if (_disposed) return;
    _snapshot = next;
    _controller.add(next);
  }
}
