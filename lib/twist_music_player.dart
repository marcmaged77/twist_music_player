/// Twist music swimlane, mini player, full player and background preview
/// playback for any Flutter app.
///
/// Call [TwistMusicPlayer.init] once before `runApp`, register
/// [TwistMusicLocalizations.delegate] on your app, then place
/// [TwistMusicSwimlane], [TwistMiniPlayer] (or [TwistPlayerHost]) and open
/// [TwistFullPlayerScreen] wherever your app decides.
library;

// Public surface. Anything not exported here is internal.
export 'src/analytics/twist_analytics.dart'
    show TwistAnalyticsEvents, TwistAnalyticsSources;
export 'src/config/twist_download_prompt_policy.dart';
export 'src/config/twist_music_config.dart';
export 'src/data/lane/twist_lane_parser.dart';
export 'src/data/lane/twist_lane_source.dart';
export 'src/data/models/twist_lane.dart';
export 'src/data/models/twist_track.dart';
export 'src/data/playback/playback_backend.dart';
export 'src/data/playback/twist_playback_engine.dart';
export 'src/data/playback/twist_playback_snapshot.dart';
export 'src/data/playback/twist_playback_status.dart';
export 'src/l10n/twist_music_localizations.dart';
export 'src/presentation/controllers/twist_lane_controller.dart'
    show TwistLaneController, TwistLaneState;
export 'src/presentation/controllers/twist_player_controller.dart';
export 'src/presentation/screens/twist_full_player_screen.dart';
export 'src/presentation/widgets/twist_mini_player.dart';
export 'src/presentation/widgets/twist_music_swimlane.dart';
export 'src/presentation/widgets/twist_player_host.dart';
export 'src/theme/twist_music_theme.dart';
export 'src/twist_music_player_impl.dart';
export 'src/utils/track_time_format.dart';
