import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:integration_test/integration_test.dart';
import 'package:twist_music_player/twist_music_player.dart';
import 'package:twist_music_player_example/main.dart' as app;

/// End-to-end run against the live endpoint on a device or simulator:
/// lane loads, a tap plays a real preview, the first tap opens the full
/// player, collapsing shows the mini player, Next raises the download prompt.
///
/// `flutter test integration_test/playback_flow_test.dart -d <device>`
void main() {
  // Let animations run on the real clock; the default policy only renders a
  // frame per pump, which would freeze the player's spring mid-expansion.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('lane, playback, full player, mini player and prompt', (tester) async {
    await app.main();
    await tester.pump();

    await _waitFor(tester, find.byType(TwistMusicSwimlane), const Duration(seconds: 10));
    final player = TwistMusicPlayer.instance;
    await _waitUntil(tester, () => player.laneController.hasContent, const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));

    final first = player.laneController.lane.tracks.first;
    expect(find.text(first.title), findsWidgets);

    await tester.tap(find.text(first.title).first);
    await _waitUntil(tester, () => player.engine.snapshot.isPlaying, const Duration(seconds: 30));
    await _waitFor(tester, find.text('PLAYING FROM TWIST MUSIC'), const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 4));
    expect(player.engine.snapshot.progressSeconds, greaterThan(0));
    expect(player.isFullPlayerOpen, isTrue);

    await tester.tap(find.byIcon(Iconsax.arrow_down_1));
    await _waitUntil(tester, () => !player.isFullPlayerOpen, const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(TwistMiniPlayerContent), findsOneWidget);
    expect(find.text('Preview'), findsWidgets);

    await player.controller.next();
    await _waitFor(tester, find.text('Download Twist'), const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 3));
    expect(player.engine.snapshot.pendingDownloadPrompt?.reason, TwistDownloadPromptReason.skip);

    await tester.tap(find.text('Not now'));
    await _waitUntil(
      tester,
      () => player.engine.snapshot.queueIndex == 1 && player.engine.snapshot.isPlaying,
      const Duration(seconds: 30),
    );
    await tester.pump(const Duration(seconds: 2));

    await player.stop();
    await tester.pump(const Duration(seconds: 1));
    expect(player.engine.snapshot.status, TwistPlaybackStatus.idle);
    await _waitUntil(
        tester, () => find.text('Now Playing').evaluate().isEmpty, const Duration(seconds: 5));
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder, Duration timeout) =>
    _waitUntil(tester, () => finder.evaluate().isNotEmpty, timeout);

Future<void> _waitUntil(WidgetTester tester, bool Function() condition, Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out after $timeout waiting for a condition');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
}
