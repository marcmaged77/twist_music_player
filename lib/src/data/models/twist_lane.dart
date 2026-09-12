import '../../config/twist_download_prompt_policy.dart';
import 'twist_track.dart';

/// The curated lane returned by the tracks endpoint: a headline, an optional
/// download link, the prompt cadence and the ordered tracks.
class TwistLane {
  const TwistLane({
    this.title,
    this.subTitle,
    this.downloadUrl,
    this.tracks = const <TwistTrack>[],
    this.downloadPrompt = TwistDownloadPromptPolicy.fallback,
  });

  static const TwistLane empty = TwistLane();

  final String? title;
  final String? subTitle;

  /// Tracker link that opens Twist when installed, else the store. Trimmed;
  /// null when the API sent nothing usable.
  final String? downloadUrl;

  final List<TwistTrack> tracks;
  final TwistDownloadPromptPolicy downloadPrompt;

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;

  @override
  String toString() => 'TwistLane(${tracks.length} tracks, title: $title, prompt: $downloadPrompt)';
}
