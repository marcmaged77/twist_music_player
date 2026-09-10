import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/twist_track.dart';
import '../../data/playback/twist_playback_engine.dart';
import '../../data/playback/twist_playback_snapshot.dart';

/// UI-facing handle on the playback engine. Mirrors every
/// [TwistPlaybackSnapshot] and forwards commands, so hosts can build their own
/// player surfaces on top of it.
class TwistPlayerController extends ChangeNotifier
    implements ValueListenable<TwistPlaybackSnapshot> {
  TwistPlayerController(this._engine) : _value = _engine.snapshot {
    _subscription = _engine.stream.listen((snapshot) {
      _value = snapshot;
      notifyListeners();
    });
  }

  final TwistPlaybackEngine _engine;
  late final StreamSubscription<TwistPlaybackSnapshot> _subscription;
  TwistPlaybackSnapshot _value;

  @override
  TwistPlaybackSnapshot get value => _value;

  double get previewSeconds => _engine.previewSeconds;
  Duration get previewDuration => _engine.previewDuration;

  Future<void> togglePlayPause() => _engine.togglePlayPause();
  Future<void> pause() => _engine.pause();
  Future<void> resume() => _engine.resume();
  Future<void> next() => _engine.next();
  Future<void> previous() => _engine.previous();
  Future<void> seek(double seconds) => _engine.seek(seconds);
  Future<void> stop() => _engine.stop();
  Future<void> selectFromQueue(TwistTrack track) => _engine.selectFromQueue(track);

  Future<void> resolveDownloadPrompt({required bool didDownload}) =>
      _engine.resolveDownloadPrompt(didDownload: didDownload);

  void acknowledgeExpansionRequest() => _engine.acknowledgeExpansionRequest();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
