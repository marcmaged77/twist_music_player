import '../../config/twist_download_prompt_policy.dart';
import '../../utils/artwork_url.dart';
import '../models/twist_lane.dart';
import '../models/twist_track.dart';

/// Maps the wire envelope of `GET /music/guest/tracks` to a [TwistLane].
///
/// Tolerant by design: unknown fields are ignored, a malformed track is
/// skipped rather than failing the lane, and order is preserved.
class TwistLaneParser {
  const TwistLaneParser._();

  static TwistLane parse(
    Map<String, dynamic> json, {
    TwistDownloadPromptPolicy fallbackPolicy = TwistDownloadPromptPolicy.fallback,
  }) {
    final tracksNode = json['tracks'];
    final items = tracksNode is Map ? tracksNode['items'] : null;
    final tracks = <TwistTrack>[];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) continue;
        final track = parseTrack(item);
        if (track != null) tracks.add(track);
      }
    }
    return TwistLane(
      title: _nonBlank(json['title']),
      subTitle: _nonBlank(json['subTitle']),
      downloadUrl: _nonBlank(json['downloadUrl']),
      tracks: tracks,
      downloadPrompt: TwistDownloadPromptPolicy.fromJson(
        json['downloadPrompt'],
        fallback: fallbackPolicy,
      ),
    );
  }

  /// Returns null when the item has no playable preview or no identity.
  static TwistTrack? parseTrack(Map<dynamic, dynamic> item) {
    final id = _int(item['id']);
    final title = _nonBlank(item['title']);
    final preview = parsePreviewUrl(_string(item['sample']));
    if (id == null || title == null || preview == null) return null;

    final artist = item['mainArtist'];
    final release = item['release'];
    final cover = item['cover'];
    return TwistTrack(
      id: id,
      title: title,
      artistName: artist is Map ? (_nonBlank(artist['name']) ?? '') : '',
      albumTitle: release is Map ? _nonBlank(release['title']) : null,
      previewUrl: preview,
      artworkSmallUrl: cover is Map ? normalizeArtworkUrl(_string(cover['small'])) : null,
      artworkMediumUrl: cover is Map ? normalizeArtworkUrl(_string(cover['medium'])) : null,
      artworkLargeUrl: cover is Map ? normalizeArtworkUrl(_string(cover['large'])) : null,
      fullDurationSeconds: _int(item['duration']) ?? 0,
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static String? _nonBlank(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
