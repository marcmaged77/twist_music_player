import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'analytics/twist_analytics.dart';
import 'config/twist_music_config.dart';
import 'data/models/twist_track.dart';
import 'data/playback/audio_session_controller.dart';
import 'data/playback/just_audio_backend.dart';
import 'data/playback/playback_backend.dart';
import 'data/playback/twist_audio_handler.dart';
import 'data/playback/twist_playback_engine.dart';
import 'data/playback/twist_playback_snapshot.dart';
import 'presentation/controllers/twist_lane_controller.dart';
import 'presentation/controllers/twist_player_controller.dart';
import 'presentation/screens/twist_full_player_screen.dart';
import 'presentation/twist_player_surface.dart';
import 'presentation/widgets/download_prompt_sheet.dart';
import 'presentation/widgets/twist_player_host.dart';
import 'theme/twist_colors.dart';
import 'utils/artwork_palette.dart';

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
    _engineSubscription = engine.stream.listen(_onSnapshot);
    _updatePalette(engine.snapshot.currentTrack);
  }

  static TwistMusicPlayer? _instance;

  static bool get isInitialized => _instance != null;

  static TwistMusicPlayer get instance {
    final player = _instance;
    if (player == null) {
      throw StateError('TwistMusicPlayer.init() must be called before using the package.');
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
  late final StreamSubscription<TwistPlaybackSnapshot> _engineSubscription;

  /// True while a track is loaded (mini player worth showing).
  ValueListenable<bool> get isActive => _isActive;

  /// Loading state of the shared lane.
  ValueListenable<TwistLaneState> get laneState => laneController.stateListenable;

  void _onSnapshot(TwistPlaybackSnapshot snapshot) {
    _isActive.value = snapshot.isActive;
    _updatePalette(snapshot.currentTrack);
  }

  // Artwork palette -----------------------------------------------------------

  final ValueNotifier<ArtworkPalette> _palette =
      ValueNotifier<ArtworkPalette>(ArtworkPalette.fallback);
  final ArtworkPaletteResolver _paletteResolver = ArtworkPaletteResolver();
  Uri? _paletteUrl;

  /// Dominant colours of the current artwork, resolved as soon as a track
  /// starts so the full player never extracts them mid-animation.
  ValueListenable<ArtworkPalette> get artworkPalette => _palette;

  Future<void> _updatePalette(TwistTrack? track) async {
    final url = track?.preferredFullArtworkUrl;
    if (url == _paletteUrl) return;
    _paletteUrl = url;
    if (url == null) {
      _palette.value = ArtworkPalette.fallback;
      return;
    }
    try {
      final palette = await _paletteResolver.resolve(CachedNetworkImageProvider(url.toString()));
      if (_paletteUrl == url && _instance == this) _palette.value = palette;
    } catch (error, stack) {
      config.onError?.call(error, stack);
    }
  }

  // Surface -------------------------------------------------------------------

  TwistPlayerSurface? _surface;

  /// The mounted [TwistPlayerHost], if any. It expands the player in place
  /// and presents sheets in its own layer.
  bool get hasSurface => _surface != null;

  void attachSurface(TwistPlayerSurface surface) {
    _surface = surface;
  }

  void detachSurface(TwistPlayerSurface surface) {
    if (identical(_surface, surface)) _surface = null;
  }

  // Navigation ----------------------------------------------------------------

  final ValueNotifier<bool> _packageRouteOpen = ValueNotifier<bool>(false);
  int _openRoutes = 0;

  /// True while the route-based full player or a modal sheet of the package
  /// is on screen (hosts without [TwistPlayerHost]).
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
  /// [TwistPlayerHost].
  BuildContext _navigatorContext(BuildContext context) {
    if (Navigator.maybeOf(context, rootNavigator: true) != null) return context;
    final hosted = TwistPlayerHost.navigatorContextOf(context);
    if (hosted != null) return hosted;
    throw FlutterError('twist_music_player: no Navigator found. Place the widget under a '
        'Navigator or inside TwistPlayerHost wrapping the MaterialApp child.');
  }

  bool _fullPlayerOpen = false;

  /// True while the full player is expanded or pushed.
  bool get isFullPlayerOpen => _surface?.isExpanded ?? _fullPlayerOpen;

  /// Expands the player in place when a [TwistPlayerHost] is mounted,
  /// otherwise pushes [TwistFullPlayerRoute] on the root navigator. A
  /// download prompt raised while the player is open shows on top of it.
  Future<void> openFullPlayer(BuildContext context, {String? analyticsVia}) async {
    if (isFullPlayerOpen || !engine.snapshot.isActive) return;
    final track = engine.snapshot.currentTrack;
    if (analyticsVia != null && track != null) {
      analytics.playerExpanded(track, via: analyticsVia);
    }

    final surface = _surface;
    if (surface != null) {
      await surface.expand();
      return;
    }

    final navigator = Navigator.of(_navigatorContext(context), rootNavigator: true);
    _fullPlayerOpen = true;
    _routeOpened();
    try {
      await navigator.push<Object?>(TwistFullPlayerRoute());
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
  /// chosen and resolves the engine. Inside a [TwistPlayerHost] the sheet
  /// rises in the host's layer, over the expanded player when it is open.
  Future<void> presentDownloadPrompt(
    BuildContext context,
    TwistDownloadPromptRequest request, {
    required String source,
  }) async {
    final surface = _surface;
    var effectiveSource = source;
    bool didDownload;
    if (surface != null) {
      if (surface.isExpanded) effectiveSource = TwistAnalyticsSources.promptFullScreen;
      analytics.downloadPromptShown(request.track, source: effectiveSource);
      didDownload = await surface.showSheet<bool>(
            (_) => const DecoratedBox(
              decoration: BoxDecoration(
                color: TwistColors.darkNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: TwistDownloadPromptBody(),
            ),
          ) ??
          false;
    } else {
      analytics.downloadPromptShown(request.track, source: effectiveSource);
      _routeOpened();
      try {
        didDownload = await showTwistDownloadPrompt(_navigatorContext(context)) ?? false;
      } finally {
        _routeClosed();
      }
    }
    analytics.downloadPromptAction(request.track,
        action: didDownload ? 'download' : 'not_now', source: effectiveSource);
    if (didDownload) await openDownloadLink(source: effectiveSource, logClick: false);
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
    await _engineSubscription.cancel();
    _isActive.dispose();
    _palette.dispose();
    _packageRouteOpen.dispose();
    controller.dispose();
    laneController.dispose();
    await _audioHandler?.dispose();
    await engine.dispose();
  }
}
