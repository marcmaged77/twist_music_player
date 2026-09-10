import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'analytics/twist_analytics.dart';
import 'config/twist_music_config.dart';
import 'data/playback/audio_session_controller.dart';
import 'data/playback/just_audio_backend.dart';
import 'data/playback/playback_backend.dart';
import 'data/playback/twist_audio_handler.dart';
import 'data/playback/twist_playback_engine.dart';
import 'data/playback/twist_playback_snapshot.dart';
import 'presentation/controllers/twist_lane_controller.dart';
import 'presentation/controllers/twist_player_controller.dart';
import 'presentation/screens/twist_full_player_screen.dart';
import 'presentation/widgets/download_prompt_sheet.dart';
import 'presentation/widgets/twist_player_host.dart';

/// Process-wide entry point. Call [init] once before `runApp`; every widget
/// in the package resolves its dependencies through [instance].
class TwistMusicPlayer {
  TwistMusicPlayer._({
    required this.config,
    required this.engine,
    required this.analytics,
    required this.laneController,
    required this.controller,
    required TwistAudioHandler? audioHandler,
  }) : _audioHandler = audioHandler {
    _isActive = ValueNotifier<bool>(engine.snapshot.isActive);
    _activeSubscription = engine.stream.listen((snapshot) {
      _isActive.value = snapshot.isActive;
    });
  }

  static TwistMusicPlayer? _instance;

  static bool get isInitialized => _instance != null;

  static TwistMusicPlayer get instance {
    final player = _instance;
    if (player == null) {
      throw StateError(
          'TwistMusicPlayer.init() must be called before using the package.');
    }
    return player;
  }

  /// Creates the engine, the controllers and (by default) the audio_service
  /// handler for lock-screen controls. Idempotent: a second call returns the
  /// existing instance.
  ///
  /// [backend], [session] and [enableBackgroundControls] exist for tests and
  /// for hosts that bring their own player implementation.
  static Future<TwistMusicPlayer> init(
    TwistMusicConfig config, {
    PlaybackBackend? backend,
    PlaybackSessionController? session,
    bool enableBackgroundControls = true,
  }) async {
    final existing = _instance;
    if (existing != null) return existing;

    final engine = TwistPlaybackEngine(
      backend: backend ?? JustAudioBackend(),
      session: session ?? AudioSessionPlaybackController(),
      previewDuration: config.previewDuration,
      promptPolicy: config.fallbackPromptPolicy,
      onError: config.onError,
    );
    final analytics = TwistAnalytics(config.onAnalyticsEvent);
    final laneController = TwistLaneController(
      source: config.laneSource,
      engine: engine,
      analytics: analytics,
      onError: config.onError,
    );
    final controller = TwistPlayerController(engine);

    TwistAudioHandler? handler;
    if (enableBackgroundControls) {
      try {
        handler = await AudioService.init<TwistAudioHandler>(
          builder: () => TwistAudioHandler(engine),
          config: AudioServiceConfig(
            androidNotificationChannelId: config.androidNotificationChannelId,
            androidNotificationChannelName: 'Music playback',
            androidNotificationIcon: config.androidNotificationIcon,
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            androidShowNotificationBadge: false,
          ),
        );
      } catch (error, stack) {
        debugPrint('[twist_music_player] background controls unavailable: $error');
        config.onError?.call(error, stack);
      }
    }

    final player = TwistMusicPlayer._(
      config: config,
      engine: engine,
      analytics: analytics,
      laneController: laneController,
      controller: controller,
      audioHandler: handler,
    );
    _instance = player;
    return player;
  }

  /// Tears the instance down so [init] can run again. Background controls
  /// cannot be re-registered in the same process; tests should pass
  /// `enableBackgroundControls: false`.
  @visibleForTesting
  static Future<void> reset() async {
    final player = _instance;
    _instance = null;
    await player?._dispose();
  }

  final TwistMusicConfig config;
  final TwistPlaybackEngine engine;
  final TwistAnalytics analytics;
  final TwistLaneController laneController;
  final TwistPlayerController controller;
  final TwistAudioHandler? _audioHandler;

  late final ValueNotifier<bool> _isActive;
  late final StreamSubscription<TwistPlaybackSnapshot> _activeSubscription;

  /// True while a track is loaded (mini player worth showing).
  ValueListenable<bool> get isActive => _isActive;

  /// Loading state of the shared lane.
  ValueListenable<TwistLaneState> get laneState => laneController.stateListenable;

  // Navigation ----------------------------------------------------------------

  final ValueNotifier<bool> _packageRouteOpen = ValueNotifier<bool>(false);
  int _openRoutes = 0;

  /// True while the full player or one of the package's sheets is on screen.
  /// [TwistPlayerHost] hides the docked mini player during that time because
  /// it paints above every route.
  ValueListenable<bool> get isPackageRouteOpen => _packageRouteOpen;

  void _routeOpened() {
    _openRoutes++;
    _packageRouteOpen.value = true;
  }

  void _routeClosed() {
    _openRoutes = _openRoutes > 0 ? _openRoutes - 1 : 0;
    _packageRouteOpen.value = _openRoutes > 0;
  }

  /// A context that can push routes: [context] itself when it is under a
  /// Navigator, otherwise the Navigator found inside the enclosing
  /// [TwistPlayerHost] (whose mini player lives above the Navigator).
  BuildContext _navigatorContext(BuildContext context) {
    if (Navigator.maybeOf(context, rootNavigator: true) != null) return context;
    final hosted = TwistPlayerHost.navigatorContextOf(context);
    if (hosted != null) return hosted;
    throw FlutterError(
        'twist_music_player: no Navigator found. Place the widget under a '
        'Navigator or inside TwistPlayerHost wrapping the MaterialApp child.');
  }

  bool _fullPlayerOpen = false;
  bool get isFullPlayerOpen => _fullPlayerOpen;

  /// Pushes the full player on the root navigator. When a download prompt
  /// becomes due while it is open, the player collapses first and the prompt
  /// follows, as on iOS.
  ///
  /// [expandFrom] is the global rectangle the page should grow out of, e.g.
  /// the mini player's bounds; without it the page slides up.
  Future<void> openFullPlayer(
    BuildContext context, {
    String? analyticsVia,
    Rect? expandFrom,
  }) async {
    if (_fullPlayerOpen || !engine.snapshot.isActive) return;
    final track = engine.snapshot.currentTrack;
    if (analyticsVia != null && track != null) {
      analytics.playerExpanded(track, via: analyticsVia);
    }
    final navigator = Navigator.of(_navigatorContext(context), rootNavigator: true);
    _fullPlayerOpen = true;
    _routeOpened();
    try {
      final result =
          await navigator.push<Object?>(TwistFullPlayerRoute(expandFrom: expandFrom));
      _fullPlayerOpen = false;
      if (result is TwistDownloadPromptRequest) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!navigator.mounted) return;
        await presentDownloadPrompt(navigator.context, result,
            source: TwistAnalyticsSources.promptFullScreen);
      }
    } finally {
      _fullPlayerOpen = false;
      _routeClosed();
    }
  }

  // Download prompt -----------------------------------------------------------

  TwistDownloadPromptRequest? _claimedPrompt;

  /// First caller wins; later callers for the same request get false so a
  /// prompt is presented exactly once.
  bool claimDownloadPrompt(TwistDownloadPromptRequest request) {
    if (_claimedPrompt == request) return false;
    _claimedPrompt = request;
    return true;
  }

  /// Shows the prompt sheet, logs the outcome, opens the download link when
  /// chosen and resolves the engine.
  Future<void> presentDownloadPrompt(
    BuildContext context,
    TwistDownloadPromptRequest request, {
    required String source,
  }) async {
    analytics.downloadPromptShown(request.track, source: source);
    _routeOpened();
    bool didDownload;
    try {
      didDownload = await showTwistDownloadPrompt(_navigatorContext(context),
              request: request) ??
          false;
    } finally {
      _routeClosed();
    }
    analytics.downloadPromptAction(request.track,
        action: didDownload ? 'download' : 'not_now', source: source);
    if (didDownload) await openDownloadLink(source: source, logClick: false);
    await engine.resolveDownloadPrompt(didDownload: didDownload);
    _claimedPrompt = null;
  }

  // Download link -------------------------------------------------------------

  /// The lane's tracker link when usable, else the configured store page.
  Uri get downloadUrl => _laneDownloadUrl ?? config.downloadFallbackUrl;

  Uri? get _laneDownloadUrl {
    final raw = laneController.lane.downloadUrl;
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  /// Opens the download link in an external app, falling back to the store
  /// page when the tracker link cannot be launched.
  Future<bool> openDownloadLink({required String source, bool logClick = true}) async {
    if (logClick) {
      analytics.downloadClicked(engine.snapshot.currentTrack, source: source);
    }
    final primary = _laneDownloadUrl;
    if (primary != null && await _launch(primary)) return true;
    return _launch(config.downloadFallbackUrl);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stack) {
      config.onError?.call(error, stack);
      return false;
    }
  }

  // Lifecycle -----------------------------------------------------------------

  /// Stops playback. With [resetSession] the once-per-session flags and the
  /// cached lane are cleared too (call on logout or account switch).
  Future<void> stop({bool resetSession = false}) async {
    await engine.stop();
    if (resetSession) {
      engine.resetSessionFlags();
      laneController.invalidate();
    }
  }

  Future<void> _dispose() async {
    await _activeSubscription.cancel();
    _isActive.dispose();
    _packageRouteOpen.dispose();
    controller.dispose();
    laneController.dispose();
    await _audioHandler?.dispose();
    await engine.dispose();
  }
}
