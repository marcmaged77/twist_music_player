import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:integration_test/integration_test.dart';
import 'package:twist_music_player/twist_music_player.dart';
import 'package:twist_music_player_example/main.dart' as app;

/// Captures the pub.dev screenshots against a live lane:
/// `flutter drive --driver=test_driver/integration_test.dart
///   --target=integration_test/screenshots_test.dart -d <device>
///   --dart-define=TWIST_TRACKS_URL=... --dart-define=TWIST_STORE_URL=...`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('swimlane, full player, mini player, prompt', (tester) async {
    await app.main();
    await tester.pump();
    final player = TwistMusicPlayer.instance;
    await _waitUntil(tester, () => player.laneController.hasContent, const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 3));
    await binding.takeScreenshot('swimlane');

    final first = player.laneController.lane.tracks.first;
    await tester.tap(find.text(first.title).first);
    await _waitUntil(tester, () => player.engine.snapshot.isPlaying, const Duration(seconds: 30));
    await _waitUntil(tester, () => player.isFullPlayerOpen, const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 4));
    await binding.takeScreenshot('full_player');

    await tester.tap(find.byIcon(Iconsax.arrow_down_1));
    await _waitUntil(tester, () => !player.isFullPlayerOpen, const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 2));
    await binding.takeScreenshot('mini_player');

    await player.controller.next();
    await _waitFor(tester, find.text('Download Twist'), const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await binding.takeScreenshot('download_prompt');

    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(seconds: 1));
    await player.stop();
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder, Duration timeout) =>
    _waitUntil(tester, () => finder.evaluate().isNotEmpty, timeout);

Future<void> _waitUntil(WidgetTester tester, bool Function() condition, Duration timeout) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out after $timeout');
    await tester.pump(const Duration(milliseconds: 250));
  }
}
