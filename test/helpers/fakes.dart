import 'dart:async';

import 'package:twist_music_player/twist_music_player.dart';

/// In-memory [PlaybackBackend] that records calls and lets tests push events.
class FakeBackend implements PlaybackBackend {
  final _states = StreamController<PlaybackBackendState>.broadcast();
  final _positions = StreamController<Duration>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  final List<String> log = <String>[];
  Uri? loadedUrl;
  bool playing = false;
  Duration position = Duration.zero;
  bool failLoad = false;
  int loads = 0;

  @override
  Stream<PlaybackBackendState> get stateStream => _states.stream;
  @override
  Stream<Duration> get positionStream => _positions.stream;
  @override
  Stream<Object> get errorStream => _errors.stream;

  @override
  Future<void> load(Uri url) async {
    loads++;
    if (failLoad) throw Exception('load failed');
    loadedUrl = url;
    playing = false;
    position = Duration.zero;
    log.add('load ${url.pathSegments.last}');
  }

  @override
  Future<void> play() async {
    playing = true;
    log.add('play');
  }

  @override
  Future<void> pause() async {
    playing = false;
    log.add('pause');
  }

  @override
  Future<void> seek(Duration position) async {
    this.position = position;
    log.add('seek ${position.inMilliseconds}');
  }

  @override
  Future<void> stop() async {
    playing = false;
    loadedUrl = null;
    log.add('stop');
  }

  @override
  Future<void> dispose() async {
    await _states.close();
    await _positions.close();
    await _errors.close();
  }

  Future<void> emitReady() => _emit(() => _states.add(PlaybackBackendState.ready));
  Future<void> emitCompleted() => _emit(() => _states.add(PlaybackBackendState.completed));
  Future<void> emitPosition(double seconds) =>
      _emit(() => _positions.add(Duration(milliseconds: (seconds * 1000).round())));
  Future<void> emitError(Object error) => _emit(() => _errors.add(error));

  Future<void> _emit(void Function() action) async {
    action();
    await pumpEventQueue();
  }
}

/// In-memory [PlaybackSessionController].
class FakeSession implements PlaybackSessionController {
  final _interruptions = StreamController<PlaybackInterruption>.broadcast();
  final _noisy = StreamController<void>.broadcast();

  int activations = 0;
  int deactivations = 0;
  bool refuse = false;

  @override
  Future<void> activate() async {
    if (refuse) throw StateError('refused');
    activations++;
  }

  @override
  Future<void> deactivate() async {
    deactivations++;
  }

  @override
  Stream<PlaybackInterruption> get interruptions => _interruptions.stream;
  @override
  Stream<void> get becomingNoisy => _noisy.stream;

  @override
  Future<void> dispose() async {
    await _interruptions.close();
    await _noisy.close();
  }

  Future<void> interrupt() async {
    _interruptions.add(const PlaybackInterruption.began());
    await pumpEventQueue();
  }

  Future<void> endInterruption({required bool shouldResume}) async {
    _interruptions.add(PlaybackInterruption.ended(shouldResume: shouldResume));
    await pumpEventQueue();
  }

  Future<void> becomeNoisy() async {
    _noisy.add(null);
    await pumpEventQueue();
  }
}

/// Drains microtasks so stream listeners and awaited engine work run. Uses
/// microtasks, not timers, so it also works inside `testWidgets`.
Future<void> pumpEventQueue([int times = 40]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.microtask(() {});
  }
}

TwistTrack track(int id, {String? title}) => TwistTrack(
      id: id,
      title: title ?? 'Track $id',
      artistName: 'Artist $id',
      previewUrl: Uri.parse('https://cdn.example.com/previews/$id.aac'),
      albumTitle: 'Album $id',
      fullDurationSeconds: 200 + id,
    );

List<TwistTrack> tracks(int count) => [for (var i = 1; i <= count; i++) track(i)];

TwistLane lane(int count, {String? title, TwistDownloadPromptPolicy? policy}) => TwistLane(
      title: title ?? 'Hot Lane',
      subTitle: 'Promoted',
      downloadUrl: 'https://twist.example.com/get',
      tracks: tracks(count),
      downloadPrompt: policy ?? TwistDownloadPromptPolicy.fallback,
    );

/// Lane source that counts loads and can be told to fail.
class CountingLaneSource implements TwistLaneSource {
  CountingLaneSource(this.lane, {this.fail = false});

  final TwistLane lane;
  bool fail;
  int loads = 0;

  @override
  Future<TwistLane> load() async {
    loads++;
    if (fail) throw const TwistLaneException('boom');
    return lane;
  }
}

/// Collects analytics callback invocations.
class AnalyticsRecorder {
  final List<(String, Map<String, Object>)> events = [];

  void call(String name, Map<String, Object> parameters) => events.add((name, parameters));

  List<String> get names => [for (final e in events) e.$1];

  Map<String, Object>? paramsOf(String name) {
    for (final event in events) {
      if (event.$1 == name) return event.$2;
    }
    return null;
  }
}
