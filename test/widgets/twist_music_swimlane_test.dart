import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/src/presentation/widgets/swimlane/track_card.dart';
import 'package:twist_music_player/twist_music_player.dart';

import '../helpers/fakes.dart';
import '../helpers/test_player.dart';

void main() {
  tearDown(() => TwistMusicPlayer.reset());

  testWidgets('shows the skeleton, then the lane, and reports availability', (tester) async {
    final setup = await initTestPlayer(source: CountingLaneSource(lane(3, title: 'Hot Lane')));
    final availability = <bool>[];

    await pumpTestApp(
      tester,
      SingleChildScrollView(
        child: TwistMusicSwimlane(
          autoScrollInterval: null,
          onContentAvailabilityChanged: availability.add,
        ),
      ),
    );
    expect(find.text('Hot Lane'), findsNothing);

    await tester.pump();
    await tester.pump();
    expect(find.text('Hot Lane'), findsOneWidget);
    expect(find.text('Promoted'), findsOneWidget);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 1'), findsOneWidget);
    expect(availability, [false, true]);
    expect(setup.analytics.names, [TwistAnalyticsEvents.laneLoaded]);
  });

  testWidgets('the promo chip opens the download link and logs the header source', (tester) async {
    final setup = await initTestPlayer(source: CountingLaneSource(lane(1)));
    await pumpTestApp(tester, const TwistMusicSwimlane(autoScrollInterval: null));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Promoted'));
    await tester.pump();
    expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadClicked)?['source'],
        'swimlane_header');
  });

  testWidgets('renders the empty builder when the lane is empty', (tester) async {
    await initTestPlayer(source: CountingLaneSource(lane(0)));
    final availability = <bool>[];
    await pumpTestApp(
      tester,
      TwistMusicSwimlane(
        autoScrollInterval: null,
        onContentAvailabilityChanged: availability.add,
        emptyBuilder: (_) => const Text('nothing here'),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('nothing here'), findsOneWidget);
    expect(availability, [false]);
  });

  testWidgets('uses the loading builder while loading', (tester) async {
    await initTestPlayer(source: CountingLaneSource(lane(1)));
    await pumpTestApp(
      tester,
      TwistMusicSwimlane(
        autoScrollInterval: null,
        loadingBuilder: (_) => const Text('loading...'),
      ),
    );
    expect(find.text('loading...'), findsOneWidget);
    await tester.pump();
    await tester.pump();
    expect(find.text('loading...'), findsNothing);
  });

  testWidgets('falls back to localized titles when the lane has none', (tester) async {
    await initTestPlayer(source: FixtureTwistLaneSource.lane(TwistLane(tracks: tracks(1))));
    await pumpTestApp(
      tester,
      const TwistMusicSwimlane(autoScrollInterval: null),
      locale: const Locale('ar'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('موسيقى'), findsOneWidget);
    expect(find.text('بدعم من Twist'), findsOneWidget);
  });

  testWidgets('falls back to English without the delegate', (tester) async {
    await initTestPlayer(source: FixtureTwistLaneSource.lane(TwistLane(tracks: tracks(1))));
    await pumpTestApp(
      tester,
      const TwistMusicSwimlane(autoScrollInterval: null),
      registerDelegate: false,
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Music'), findsOneWidget);
  });

  testWidgets('auto-advance wraps past the last card without jumping back', (tester) async {
    await initTestPlayer(source: CountingLaneSource(lane(3)));
    await pumpTestApp(
      tester,
      const TwistMusicSwimlane(autoScrollInterval: Duration(seconds: 2)),
    );
    await tester.pump();
    await tester.pump();
    final width = tester.getSize(find.byType(TwistMusicSwimlane)).width;
    Finder card(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(TrackCard));
    expect(tester.getCenter(card('Track 1')).dx, closeTo(width / 2, 1));

    // Each period: the timer fires and the page animation takes its zero tick,
    // then the next frame lands the card.
    for (final title in ['Track 2', 'Track 3', 'Track 1', 'Track 2']) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getCenter(card(title)).dx, closeTo(width / 2, 1));
    }
  });

  testWidgets('tapping a card plays it and marks it Now Playing', (tester) async {
    final setup = await initTestPlayer(source: CountingLaneSource(lane(2)));
    await pumpTestApp(tester, const TwistMusicSwimlane(autoScrollInterval: null));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Track 1'));
    await tester.pump();
    expect(setup.player.engine.snapshot.currentTrack?.id, 1);
    expect(setup.analytics.names, contains(TwistAnalyticsEvents.trackTapped));

    await setup.backend.emitReady();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Now Playing'), findsOneWidget);

    await setup.player.stop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Now Playing'), findsNothing);
  });

  testWidgets('the first tap of a session opens the full player', (tester) async {
    final setup = await initTestPlayer(source: CountingLaneSource(lane(2)));
    await pumpTestApp(tester, const TwistMusicSwimlane(autoScrollInterval: null));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Track 1'));
    await tester.pump();
    await setup.backend.emitReady();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(setup.player.isFullPlayerOpen, isTrue);
    expect(find.text('PLAYING FROM TWIST MUSIC'), findsOneWidget);
    expect(setup.analytics.paramsOf(TwistAnalyticsEvents.playerExpanded)?['action'],
        'swimlane_first_tap');

    await setup.player.stop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(setup.player.isFullPlayerOpen, isFalse);
  });
}
