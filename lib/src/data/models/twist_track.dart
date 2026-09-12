/// A single Twist track as the UI and the playback engine see it.
///
/// Every field is already normalised: [previewUrl] is absolute, artwork URLs
/// carry an `https:` scheme, and [fullDurationSeconds] is display-only (the
/// playable preview is always [previewDurationSeconds] long).
class TwistTrack {
  const TwistTrack({
    required this.id,
    required this.title,
    required this.artistName,
    required this.previewUrl,
    this.albumTitle,
    this.artworkSmallUrl,
    this.artworkMediumUrl,
    this.artworkLargeUrl,
    this.fullDurationSeconds = 0,
  });

  final int id;
  final String title;
  final String artistName;
  final String? albumTitle;

  /// 30-second preview stream (AAC over https).
  final Uri previewUrl;

  final Uri? artworkSmallUrl;
  final Uri? artworkMediumUrl;
  final Uri? artworkLargeUrl;

  /// Full song length in seconds as reported by the API. Not the preview length.
  final int fullDurationSeconds;

  /// Full player, swimlane cards and the mini player.
  Uri? get preferredFullArtworkUrl => artworkLargeUrl ?? artworkMediumUrl ?? artworkSmallUrl;

  /// Queue rows.
  Uri? get preferredCompactArtworkUrl => artworkMediumUrl ?? artworkSmallUrl ?? artworkLargeUrl;

  /// Lock screen and notification.
  Uri? get preferredLockScreenArtworkUrl => artworkSmallUrl ?? artworkMediumUrl ?? artworkLargeUrl;

  @override
  bool operator ==(Object other) =>
      other is TwistTrack &&
      other.id == id &&
      other.title == title &&
      other.artistName == artistName &&
      other.albumTitle == albumTitle &&
      other.previewUrl == previewUrl &&
      other.artworkSmallUrl == artworkSmallUrl &&
      other.artworkMediumUrl == artworkMediumUrl &&
      other.artworkLargeUrl == artworkLargeUrl &&
      other.fullDurationSeconds == fullDurationSeconds;

  @override
  int get hashCode => Object.hash(id, title, artistName, albumTitle, previewUrl, artworkSmallUrl,
      artworkMediumUrl, artworkLargeUrl, fullDurationSeconds);

  @override
  String toString() => 'TwistTrack($id, $title, $artistName)';
}
