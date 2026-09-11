import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twist_music_player/twist_music_player.dart';

import 'fakes.dart';

/// Initialises the facade with fakes and no platform channels.
Future<
    ({
      TwistMusicPlayer player,
      FakeBackend backend,
      FakeSession session,
      AnalyticsRecorder analytics,
    })> initTestPlayer({
  TwistLaneSource? source,
  TwistBranding? branding,
}) async {
  await TwistMusicPlayer.reset();
  final backend = FakeBackend();
  final session = FakeSession();
  final analytics = AnalyticsRecorder();
  final player = await TwistMusicPlayer.init(
    TwistMusicConfig(
      laneSource: source ?? CountingLaneSource(lane(3)),
      downloadFallbackUrl: Uri.parse('https://store.example.com/twist'),
      onAnalyticsEvent: analytics.call,
      branding: branding,
    ),
    backend: backend,
    session: session,
    enableBackgroundControls: false,
  );
  return (player: player, backend: backend, session: session, analytics: analytics);
}

/// Pumps [testApp] and unmounts it before the file-level tearDown resets the
/// facade, so widget disposal never outlives the player it was built with.
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  bool registerDelegate = true,
  TransitionBuilder? builder,
  ThemeData? theme,
}) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
  await tester.pumpWidget(testApp(
    child,
    locale: locale,
    registerDelegate: registerDelegate,
    builder: builder,
    theme: theme,
  ));
}

/// Minimal app around [child] with the package delegate registered.
Widget testApp(
  Widget child, {
  Locale locale = const Locale('en'),
  bool registerDelegate = true,
  TransitionBuilder? builder,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      if (registerDelegate) TwistMusicLocalizations.delegate,
    ],
    builder: builder,
    home: Scaffold(body: child),
  );
}
