/// Turns an API artwork value into a loadable URL.
///
/// Twist's CDN returns protocol-relative links (`//host/path`); those get an
/// `https:` scheme. Blank values and values without a host yield null.
Uri? normalizeArtworkUrl(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('//')) value = 'https:$value';
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return uri;
}

/// Parses a preview stream URL; null when it cannot be streamed.
Uri? parsePreviewUrl(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty || value.contains(' ')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
