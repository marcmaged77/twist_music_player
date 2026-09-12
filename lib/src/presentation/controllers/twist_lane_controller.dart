import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../analytics/twist_analytics.dart';
import '../../config/twist_music_config.dart';
import '../../data/lane/twist_lane_source.dart';
import '../../data/models/twist_lane.dart';
import '../../data/models/twist_track.dart';
import '../../data/playback/twist_playback_engine.dart';

/// Loading state of the shared lane.
enum TwistLaneState {
  idle,
  loading,
  loaded,

  /// No tracks, or the fetch failed. The UI shows nothing either way.
  empty;

  bool get isLoading => this == TwistLaneState.loading;
}

/// Loads the lane once per session and turns swimlane taps into playback.
/// Shared by every [TwistMusicSwimlane] instance.
class TwistLaneController extends ChangeNotifier {
  TwistLaneController({
    required TwistLaneSource source,
    required TwistPlaybackEngine engine,
    required TwistAnalytics analytics,
    TwistErrorCallback? onError,
  })  : _source = source,
        _engine = engine,
        _analytics = analytics,
        _onError = onError;

  final TwistLaneSource _source;
  final TwistPlaybackEngine _engine;
  final TwistAnalytics _analytics;
  final TwistErrorCallback? _onError;

  final ValueNotifier<TwistLaneState> _state = ValueNotifier<TwistLaneState>(TwistLaneState.idle);
  TwistLane _lane = TwistLane.empty;
  Future<void>? _inFlight;
  bool _didLogLaneLoaded = false;

  TwistLaneState get state => _state.value;
  ValueListenable<TwistLaneState> get stateListenable => _state;
  TwistLane get lane => _lane;
  bool get hasContent => state == TwistLaneState.loaded && _lane.isNotEmpty;

  /// Fetches unless already loading or loaded. `idle` and `empty` refetch,
  /// so a failed lane is retried the next time a swimlane appears.
  Future<void> loadIfNeeded() {
    final pending = _inFlight;
    if (pending != null) return pending;
    if (state == TwistLaneState.loaded) return Future<void>.value();
    return _inFlight = _load().whenComplete(() => _inFlight = null);
  }

  /// Drops the cached lane so the next [loadIfNeeded] fetches again.
  void invalidate() {
    _lane = TwistLane.empty;
    _setState(TwistLaneState.idle);
  }

  Future<void> reload() {
    invalidate();
    return loadIfNeeded();
  }

  /// Plays [track] with the whole lane as queue. The first tap of the session
  /// also arms the full-player expansion. Tapping the playing track is a no-op.
  Future<void> tapTrack(TwistTrack track) async {
    final snapshot = _engine.snapshot;
    if (snapshot.isPlaying && snapshot.currentTrack?.id == track.id) return;
    final index = _lane.tracks.indexOf(track);
    _analytics.trackTapped(track, position: index + 1);
    await _engine.play(
      track,
      queue: _lane.tracks,
      laneTitle: _lane.title,
      laneSubTitle: _lane.subTitle,
    );
    _engine.requestFirstTimeExpansion();
  }

  Future<void> _load() async {
    _setState(TwistLaneState.loading);
    try {
      final lane = await _source.load();
      _lane = lane;
      _engine.configureDownloadPrompt(lane.downloadPrompt);
      _setState(lane.isEmpty ? TwistLaneState.empty : TwistLaneState.loaded);
      if (lane.isNotEmpty && !_didLogLaneLoaded) {
        _didLogLaneLoaded = true;
        _analytics.laneLoaded(lane.tracks.length);
      }
    } catch (error, stack) {
      _lane = TwistLane.empty;
      _setState(TwistLaneState.empty);
      try {
        _onError?.call(error, stack);
      } catch (_) {
        // Host callback failures are ignored.
      }
    }
  }

  void _setState(TwistLaneState next) {
    if (_state.value == next) {
      notifyListeners();
      return;
    }
    _state.value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }
}
