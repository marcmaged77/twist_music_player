# twist_music_player

Twist music swimlane, mini player, full player and background preview playback for any Flutter app.

The package reproduces the native Twist experience shipped in the My Etisalat apps: a curated lane of 30-second previews, a persistent mini player, a full player with an "Up Next" queue, lock-screen controls, and a download prompt on a backend-configured cadence. It depends on nothing but hosted packages and never decides where or when its widgets appear. The host does.

## Install

```yaml
dependencies:
  twist_music_player: ^0.1.0
```

### Native setup (once per host app)

Background audio needs the same platform configuration `audio_service` requires.

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

<application ...>
  <service
      android:name="com.ryanheise.audioservice.AudioService"
      android:foregroundServiceType="mediaPlayback"
      android:exported="true">
    <intent-filter>
      <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
  </service>
  <receiver
      android:name="com.ryanheise.audioservice.MediaButtonReceiver"
      android:exported="true">
    <intent-filter>
      <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
  </receiver>
</application>
```

**Android** — `MainActivity.kt` must extend `com.ryanheise.audioservice.AudioServiceActivity` (or override `provideFlutterEngine`, `getCachedEngineId` and `shouldDestroyEngineWithHost` as documented by `audio_service`). The `example/` app has all three changes applied.

## Use

```dart
// main.dart — once, before runApp
await TwistMusicPlayer.init(
  TwistMusicConfig(
    laneSource: HttpTwistLaneSource(
      Uri.parse('https://api.twistmena.com/music/guest/tracks'),
      headers: () => {'Accept-Language': currentLanguageCode()},   // 'en' | 'ar'
    ),
    downloadFallbackUrl: Uri.parse('https://apps.apple.com/app/id...'),
    onAnalyticsEvent: (name, parameters) =>
        FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters),
    onError: (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack),
    branding: const TwistBranding(
      headerLogo: AssetImage('assets/twist_wordmark_blue.png'),
      promoLogo: AssetImage('assets/twist_wordmark_white.png'),
    ),
  ),
);

// MaterialApp
localizationsDelegates: const [
  ...GlobalMaterialLocalizations.delegates,
  TwistMusicLocalizations.delegate,
],
// optional: dock the mini player above your bottom bar
builder: (context, child) => TwistPlayerHost(child: child!, bottomInset: 72),

// Wherever your feed decides
if (feed.showTwist) const TwistMusicSwimlane(),

// Or place the mini player yourself; it renders nothing while idle
Positioned(left: 12, right: 12, bottom: 80, child: const TwistMiniPlayer()),

// Programmatic control
final player = TwistMusicPlayer.instance;
player.openFullPlayer(context);
player.isActive;                     // ValueListenable<bool>
player.laneState;                    // ValueListenable<TwistLaneState>
player.controller;                   // TwistPlayerController extends ChangeNotifier
player.stop(resetSession: true);     // logout
```

### Public pieces

| Piece | What it is |
|---|---|
| `TwistMusicSwimlane` | Header, peek carousel of cards, "Preview" / "Now Playing" badges. Loads the lane itself. `loadingBuilder`, `emptyBuilder`, `onContentAvailabilityChanged`. |
| `TwistMiniPlayer` | The 56-pt capsule: artwork, title, badge, play/pause, close. No positioning of its own. |
| `TwistPlayerHost` | Optional: docks `TwistMiniPlayer` above `bottomInset` with a `visible` listenable and `bottomPaddingOf(context)` for scroll views. |
| `TwistFullPlayerScreen` / `TwistFullPlayerRoute` | Promo card, artwork, scrub bar, controls, Up Next sheet, artwork-tinted gradient. Forced left-to-right. |
| `TwistPlayerController` | `ChangeNotifier` mirror of the engine for custom UIs. |
| `TwistLaneSource` | Where tracks come from. `HttpTwistLaneSource` is the default; `FixtureTwistLaneSource` for tests. |

### Behaviour, matching native

- Previews are always 30 s; progress, seek and the lock-screen duration are clamped.
- Next wraps around; Previous restarts past 3 s, otherwise wraps back; clip completion advances without wrap.
- The download prompt shows when the lane's `downloadPrompt` policy is enabled, session shows are below `maxCount`, the track has not prompted yet, and either the position reaches `intervalSeconds`, the clip completes, Next is pressed, or a queue track is picked. Previous never prompts. Fallback: one show per session at 30 s.
- The first swimlane tap of a session opens the full player; later taps only play.
- Lock screen / notification: play, pause, next, previous, seek, stop. Remote commands pass through the same prompt gate as taps.

Deliberate divergences from native: playback pauses when headphones are unplugged, `stop(resetSession: true)` exists for logout, and the player stays paused after the user taps Download.

### Analytics

Eight events with their native names and parameters reach `onAnalyticsEvent`: `twist_music_lane_loaded`, `_track_tapped`, `_player_expanded`, `_queue_opened`, `_queue_track_selected`, `_download_prompt_shown`, `_download_prompt_action`, `_download_clicked`. Nothing logs when the callback is null.

## Example

```bash
cd example
flutter run --dart-define=TWIST_TRACKS_URL=https://api.twistmena.com/music/guest/tracks
```

## Tests

```bash
flutter test
```

The engine is a pure-Dart state machine tested against an in-memory backend; the HTTP source is tested with `package:http/testing.dart`; widgets are tested with the facade initialised without platform channels (`enableBackgroundControls: false`).
