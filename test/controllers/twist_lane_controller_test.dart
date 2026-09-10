import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/src/analytics/twist_analytics.dart';
import 'package:twist_music_player/twist_music_player.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeBackend backend;
  late FakeSession session;
  late TwistPlaybackEngine engine;
  late AnalyticsRecorder analytics;
  final errors = <Object>[];

  setUp(() {
    backend = FakeBackend();
    session = FakeSession();
    engine = TwistPlaybackEngine(backend: backend, session: session);
    analytics = AnalyticsRecorder();
    errors.clear();
  });

  tearDown(() => engine.dispose());

  TwistLaneController build(TwistLaneSource source) => TwistLaneController(
        source: source,
        engine: engine,
        analytics: TwistAnalytics(analytics.call),
        onError: (error, _) => errors.add(error),
      );

  test('loads once, exposes the lane and installs the prompt policy', () async {
    const policy = TwistDownloadPromptPolicy(maxCount: 4, intervalSeconds: 12);
    final source = CountingLaneSource(lane(3, policy: policy));
    final controller = build(source);
    final states = <TwistLaneState>[];
    controller.addListener(() => states.add(controller.state));

    expect(controller.state, TwistLaneState.idle);
    await controller.loadIfNeeded();
    await controller.loadIfNeeded();
    expect(source.loads, 1);
    expect(controller.state, TwistLaneState.loaded);
    expect(controller.hasContent, isTrue);
    expect(controller.lane.tracks, hasLength(3));
    expect(states, [TwistLaneState.loading, TwistLaneState.loaded]);
    expect(engine.promptPolicy, policy);
    expect(analytics.names, [TwistAnalyticsEvents.laneLoaded]);
    expect(analytics.paramsOf(TwistAnalyticsEvents.laneLoaded), {'track_count': 3});
    controller.dispose();
  });

  test('concurrent loads share one request', () async {
    final source = CountingLaneSource(lane(1));
    final controller = build(source);
    await Future.wait([controller.loadIfNeeded(), controller.loadIfNeeded()]);
    expect(source.loads, 1);
    controller.dispose();
  });

  test('an empty lane is empty and hidden', () async {
    final controller = build(CountingLaneSource(lane(0)));
    await controller.loadIfNeeded();
    expect(controller.state, TwistLaneState.empty);
    expect(controller.hasContent, isFalse);
    expect(analytics.names, isEmpty);
    controller.dispose();
  });

  test('a failing source is empty, reported, and retried next time', () async {
    final source = CountingLaneSource(lane(2), fail: true);
    final controller = build(source);
    await controller.loadIfNeeded();
    expect(controller.state, TwistLaneState.empty);
    expect(errors.single, isA<TwistLaneException>());

    source.fail = false;
    await controller.loadIfNeeded();
    expect(source.loads, 2);
    expect(controller.state, TwistLaneState.loaded);
    controller.dispose();
  });

  test('invalidate forces a refetch', () async {
    final source = CountingLaneSource(lane(2));
    final controller = build(source);
    await controller.loadIfNeeded();
    controller.invalidate();
    expect(controller.state, TwistLaneState.idle);
    await controller.loadIfNeeded();
    expect(source.loads, 2);
    controller.dispose();
  });

  test('tapping a track plays it with the lane as queue and arms expansion', () async {
    final controller = build(CountingLaneSource(lane(3, title: 'Hot')));
    await controller.loadIfNeeded();
    final second = controller.lane.tracks[1];

    await controller.tapTrack(second);
    final s = engine.snapshot;
    expect(s.currentTrack, second);
    expect(s.queue, controller.lane.tracks);
    expect(s.queueIndex, 1);
    expect(s.laneTitle, 'Hot');
    expect(s.pendingExpansionRequest, isTrue);
    expect(analytics.paramsOf(TwistAnalyticsEvents.trackTapped), {
      'action': 'swimlane',
      'label': second.title,
      'track_id': '${second.id}',
      'artist': second.artistName,
      'position': 2,
    });
    controller.dispose();
  });

  test('tapping the playing track is ignored', () async {
    final controller = build(CountingLaneSource(lane(2)));
    await controller.loadIfNeeded();
    final first = controller.lane.tracks[0];
    await controller.tapTrack(first);
    await backend.emitReady();
    await controller.tapTrack(first);
    expect(backend.loads, 1);
    expect(analytics.names.where((n) => n == TwistAnalyticsEvents.trackTapped), hasLength(1));
    controller.dispose();
  });

  test('a throwing analytics callback is swallowed', () async {
    final controller = TwistLaneController(
      source: CountingLaneSource(lane(1)),
      engine: engine,
      analytics: TwistAnalytics((_, __) => throw StateError('host bug')),
    );
    await controller.loadIfNeeded();
    expect(controller.state, TwistLaneState.loaded);
    controller.dispose();
  });
}
