import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/twist_music_player.dart';

import '../helpers/fakes.dart';
import '../helpers/test_player.dart';

void main() {
  tearDown(() => TwistMusicPlayer.reset());

  group('TwistMiniPlayer', () {
    testWidgets('renders nothing while idle and the track once active', (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(tester, const TwistMiniPlayer());
      expect(find.text('Track 1'), findsNothing);

      await setup.player.engine.play(track(1), queue: tracks(2));
      await tester.pump();
      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);

      await setup.backend.emitReady();
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.text('Track 1'), findsNothing);
      expect(setup.player.engine.snapshot.status, TwistPlaybackStatus.idle);
    });

    testWidgets('play/pause is disabled while loading and works once ready', (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(tester, const TwistMiniPlayer());
      await setup.player.engine.play(track(1), queue: tracks(1));
      await tester.pump();

      final playButton = find.ancestor(
        of: find.byIcon(Icons.play_arrow_rounded).last,
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(playButton).onPressed, isNull);

      await setup.backend.emitReady();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();
      expect(setup.player.engine.snapshot.status, TwistPlaybackStatus.paused);

      await setup.player.stop();
      await tester.pump();
    });

    testWidgets('tapping the bar opens the full player', (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(tester, const TwistMiniPlayer());
      await setup.player.engine.play(track(1), queue: tracks(1));
      await setup.backend.emitReady();
      await tester.pump();

      await tester.tap(find.text('Track 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(setup.player.isFullPlayerOpen, isTrue);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.playerExpanded)?['action'], 'tap');

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(setup.player.isFullPlayerOpen, isFalse);
      expect(find.text('Artist 1'), findsNothing);

      await setup.player.stop();
      await tester.pump();
    });
  });

  group('TwistPlayerHost', () {
    testWidgets('reserves bottom padding only while shown', (tester) async {
      final setup = await initTestPlayer();
      final visible = ValueNotifier<bool>(true);
      addTearDown(visible.dispose);
      double? inset;
      await pumpTestApp(
        tester,
        const SizedBox.shrink(),
        builder: (context, child) => TwistPlayerHost(
          bottomInset: 60,
          visible: visible,
          child: Builder(builder: (context) {
            inset = TwistPlayerHost.bottomPaddingOf(context);
            return child!;
          }),
        ),
      );
      expect(inset, 0);

      await setup.player.engine.play(track(1), queue: tracks(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(inset, 64);
      expect(find.descendant(of: find.byType(TwistMiniPlayerContent), matching: find.text('Track 1')),
          findsOneWidget);

      visible.value = false;
      await tester.pump();
      expect(inset, 0);

      await setup.player.stop();
      await tester.pump();
      expect(inset, 0);
    });

    testWidgets('the docked bar expands in place, collapses, and shows the prompt in its layer',
        (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(
        tester,
        const SizedBox.shrink(),
        builder: (context, child) => TwistPlayerHost(bottomInset: 40, child: child!),
      );
      expect(setup.player.hasSurface, isTrue);

      await setup.player.engine.play(track(1), queue: tracks(2));
      await setup.backend.emitReady();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TwistMiniPlayerContent), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(TwistMiniPlayerContent),
        matching: find.text('Track 1'),
      ));
      await tester.pump();
      expect(setup.player.isFullPlayerOpen, isTrue);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.playerExpanded)?['action'], 'tap');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(TwistMiniPlayerContent), findsNothing);
      expect(find.text('PLAYING FROM TWIST MUSIC'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      expect(setup.player.isFullPlayerOpen, isFalse);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(TwistMiniPlayerContent), findsOneWidget);

      await setup.player.engine.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Download Twist'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadPromptShown)?['source'],
          'prompt_mini');

      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Download Twist'), findsNothing);
      expect(setup.player.engine.snapshot.queueIndex, 1);

      await setup.player.stop();
      await tester.pump();
      expect(find.byType(TwistMiniPlayerContent), findsNothing);
    });

    testWidgets('a prompt due while expanded collapses the player first', (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(
        tester,
        const SizedBox.shrink(),
        builder: (context, child) => TwistPlayerHost(child: child!),
      );
      await setup.player.engine.play(track(1), queue: tracks(2));
      await setup.backend.emitReady();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.descendant(
        of: find.byType(TwistMiniPlayerContent),
        matching: find.text('Track 1'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(setup.player.isFullPlayerOpen, isTrue);
      expect(find.byType(TwistMiniPlayerContent), findsNothing);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
      expect(setup.player.engine.snapshot.pendingDownloadPrompt?.reason,
          TwistDownloadPromptReason.skip);
      // Collapse spring (two frames), the 120 ms breather, then the sheet slide.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(setup.player.isFullPlayerOpen, isFalse);
      expect(find.text('Download Twist'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadPromptShown)?['source'],
          'prompt_full_screen');

      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(setup.player.engine.snapshot.queueIndex, 1);

      await setup.player.stop();
      await tester.pump();
    });
  });

  group('TwistFullPlayerScreen', () {
    testWidgets('shows the track, 0:30 and forces left-to-right', (tester) async {
      final setup = await initTestPlayer();
      await setup.player.engine.play(track(1), queue: tracks(3));
      await setup.backend.emitReady();
      await pumpTestApp(
        tester,
        const TwistFullPlayerScreen(),
        locale: const Locale('ar'),
      );
      await tester.pump();

      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);
      expect(find.text('يتم التشغيل من TWIST MUSIC'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      final direction = Directionality.of(tester.element(find.text('Track 1')));
      expect(direction, TextDirection.ltr);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
      expect(setup.player.engine.snapshot.pendingDownloadPrompt?.reason,
          TwistDownloadPromptReason.skip);

      await setup.player.stop();
      await tester.pump();
    });

    testWidgets('openFullPlayer pushes the route and a stop pops it', (tester) async {
      final setup = await initTestPlayer();
      await setup.player.engine.play(track(1), queue: tracks(1));
      late BuildContext context;
      await pumpTestApp(
        tester,
        Builder(builder: (c) {
          context = c;
          return const SizedBox.shrink();
        }),
      );

      final opening = setup.player.openFullPlayer(context, analyticsVia: 'tap');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(setup.player.isFullPlayerOpen, isTrue);
      expect(find.text('Track 1'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.playerExpanded)?['action'], 'tap');

      await setup.player.stop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await opening;
      expect(setup.player.isFullPlayerOpen, isFalse);
      expect(find.text('Track 1'), findsNothing);
    });

    testWidgets('a due prompt collapses the full player, then shows the sheet', (tester) async {
      final setup = await initTestPlayer();
      await setup.player.engine.play(track(1), queue: tracks(2));
      await setup.backend.emitReady();
      late BuildContext context;
      await pumpTestApp(
        tester,
        Builder(builder: (c) {
          context = c;
          return const SizedBox.shrink();
        }),
      );
      final opening = setup.player.openFullPlayer(context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Download Twist'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadPromptShown)?['source'],
          'prompt_full_screen');

      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await opening;
      expect(setup.player.engine.snapshot.queueIndex, 1);
      expect(setup.player.isFullPlayerOpen, isFalse);

      await setup.player.stop();
      await tester.pump();
    });
  });

  group('download prompt', () {
    testWidgets('the mini player presents a due prompt once and resolves it', (tester) async {
      final setup = await initTestPlayer();
      await pumpTestApp(tester, const TwistMiniPlayer());
      await setup.player.engine.play(track(1), queue: tracks(2));
      await setup.backend.emitReady();
      await tester.pump();

      await setup.player.engine.next();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Download Twist'), findsOneWidget);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadPromptShown)?['source'],
          'prompt_mini');
      expect(
          setup.analytics.names.where((n) => n == TwistAnalyticsEvents.downloadPromptShown),
          hasLength(1));

      await tester.tap(find.text('Not now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Download Twist'), findsNothing);
      expect(setup.analytics.paramsOf(TwistAnalyticsEvents.downloadPromptAction)?['action'],
          'not_now');
      expect(setup.player.engine.snapshot.queueIndex, 1);

      await setup.player.stop();
      await tester.pump();
    });
  });
}
